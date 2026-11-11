// Seeds the finished SMPL tournament (auction + 32 matches) through the app's
// own services on a fake Firestore, then writes every document to a JSON file
// for upload. Run explicitly:
//   flutter test tool/seed_smpl/seed_smpl_test.dart
// Input/output paths: SEED_INPUT (default /tmp/crickex2/seed_input.json),
// SEED_OUTPUT (default /tmp/crickex2/seed_out.json).
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:data/api/auction/auction_models.dart';
import 'package:data/api/ball_score/ball_score_model.dart';
import 'package:data/api/innings/inning_model.dart';
import 'package:data/api/match/match_model.dart';
import 'package:data/api/match_event/match_event_model.dart';
import 'package:data/api/partnership/partnership_model.dart';
import 'package:data/api/tournament/tournament_details.dart';
import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:data/api/user/user_models.dart';
import 'package:data/service/auction/auction_service.dart';
import 'package:data/service/ball_score/ball_score_service.dart';
import 'package:data/service/device/device_service.dart';
import 'package:data/service/innings/inning_service.dart';
import 'package:data/service/match/match_service.dart';
import 'package:data/service/match_event/match_event_service.dart';
import 'package:data/service/partnership/partnership_service.dart';
import 'package:data/service/team/team_service.dart';
import 'package:data/service/tournament/tournament_service.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/service/user/user_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'seed SMPL',
    () async {
      final env = Platform.environment;
      final input = jsonDecode(
        File(env['SEED_INPUT'] ?? '/tmp/crickex2/seed_input.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final seeder = _Seeder(input);
      await seeder.run();
      final docs = await seeder.export();
      File(env['SEED_OUTPUT'] ?? '/tmp/crickex2/seed_out.json')
          .writeAsStringSync(jsonEncode(docs));
      // ignore: avoid_print
      print('exported ${docs.length} documents');
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

class _FakeDevice extends Fake implements DeviceService {}

class _Inning {
  final InningModel model;
  int runs = 0;
  int wickets = 0;

  _Inning(this.model);
}

class _Seeder {
  final Map<String, dynamic> input;
  final db = FakeFirebaseFirestore();
  late final UserService users = UserService(null, db, _FakeDevice());
  late final TeamService teams = TeamService(db, users);
  late final MatchService matches = MatchService(db, teams, users);
  late final InningsService innings = InningsService(db);
  late final BallScoreService balls = BallScoreService(db, matches, innings);
  late final MatchEventService events = MatchEventService(db);
  late final PartnershipService partnerships = PartnershipService(db);
  late final TournamentService tournaments =
      TournamentService(db, teams, matches, users);
  late final TournamentTeamService tournamentTeams = TournamentTeamService(db);
  late final AuctionService auctions = AuctionService(db);

  late final String owner = input['owner'] as String;
  late final String auctionId = input['auction_id'] as String;
  late String tournamentId;

  /// CrickEX player id -> Khelo user id.
  final players = <String, String>{};

  _Seeder(this.input);

  String teamId(String auctionTeamId) => 'auction_${auctionId}_$auctionTeamId';

  Future<void> run() async {
    await _writeAuction();
    tournamentId = await auctions.completeAndGenerateTournament(
      auctionId,
      owner,
      markRemainingUnsold: true,
    );
    await _updateTournament();
    await _updateTeams();
    await _mapPlayers();
    await _applyRosterChanges();
    for (final match in (input['matches'] as List).cast<Map>()) {
      await _seedMatch(Map<String, dynamic>.from(match));
    }
  }

  Future<void> _writeAuction() async {
    final auction =
        Auction.fromJson(Map<String, dynamic>.from(input['auction'] as Map));
    await db.collection('auctions').doc(auction.id).set(auction.toJson());
    for (final entry in (input['auction_log'] as List).cast<Map>()) {
      final ref = db.collection('auctions').doc(auction.id).collection('log');
      final doc = ref.doc();
      await doc.set({
        'id': doc.id,
        'type': entry['type'],
        'player_id': entry['player_id'],
        'team_id': entry['team_id'],
        'amount': entry['amount'],
        'by': owner,
        'created_at': Timestamp.fromDate(DateTime.parse(entry['at'] as String)),
      });
    }
    final photos = Map<String, dynamic>.from(input['photos'] as Map);
    for (final entry in photos.entries) {
      await _writePhoto(entry.key, entry.value as String);
    }
    final logos = Map<String, dynamic>.from(input['team_logos'] as Map);
    for (final team in auction.teams) {
      final logo = logos[team.id] as String?;
      if (logo != null) await _writePhoto(auction.teamLogoId(team), logo);
    }
  }

  Future<void> _writePhoto(String id, String base64Jpeg) =>
      db.collection('photos').doc(id).set({
        'data': Blob(base64Decode(base64Jpeg)),
        'auction_id': auctionId,
        'created_by': owner,
        'updated_at': Timestamp.now(),
      });

  Future<void> _updateTournament() async {
    final info = Map<String, dynamic>.from(input['tournament'] as Map);
    final tournament = await tournaments.getTournamentById(tournamentId);
    await tournaments.createTournament(tournament.copyWith(
      name: info['name'] as String,
      profile_img_url: 'data:image/jpeg;base64,${info['logo']}',
      banner_img_url: 'data:image/jpeg;base64,${info['cover']}',
      start_date: DateTime.parse(info['start'] as String),
      end_date: DateTime.parse(info['end'] as String),
    ));
    await tournaments.saveTournamentDetails(
      tournamentId,
      TournamentDetails(
        ground: info['venue'] as String,
        ballType: BallType.leather,
        oversPerMatch: info['overs'] as int,
      ),
    );
  }

  Future<void> _updateTeams() async {
    final extras = Map<String, dynamic>.from(input['team_extras'] as Map);
    for (final entry in extras.entries) {
      final id = teamId(entry.key);
      final doc = (await db.collection('teams').doc(id).get()).data()!;
      final extra = Map<String, dynamic>.from(entry.value as Map);
      await tournamentTeams.saveTeam(
        teamId: id,
        userId: owner,
        name: doc['name'] as String,
        poolId: doc['pool_id'] as String?,
        shortName: extra['short_name'] as String?,
        logo: doc['profile_img_url'] as String?,
        isNew: false,
      );
      await db.collection('teams').doc(id).update({
        'owner_name': extra['owner_name'],
        'color': extra['color'],
      });
    }
  }

  Future<void> _mapPlayers() async {
    final auctionIds = Map<String, dynamic>.from(input['auction_pid'] as Map);
    for (final entry in auctionIds.entries) {
      final userId = 'auction_${auctionId}_${entry.value}';
      if ((await db.collection('users').doc(userId).get()).exists) {
        players[entry.key] = userId;
      }
    }
  }

  Future<TournamentTeam> _team(String id) async {
    final doc = await db.collection('teams').doc(id).get();
    return TournamentTeam.fromJson(doc.data()!);
  }

  /// Squad changes the organizer made after the auction: replacements and
  /// one transfer.
  Future<void> _applyRosterChanges() async {
    for (final change in (input['roster_changes'] as List).cast<Map>()) {
      final cx = change['cx'] as String;
      final name = change['name'] as String;
      final to = await _team(teamId(change['to_team'] as String));
      final existing = await tournamentTeams.getPlayers(to);
      final from = change['from_team'] as String?;
      if (from != null) {
        final userId = players[cx]!;
        await tournamentTeams.removePlayer(await _team(teamId(from)), userId);
        await tournamentTeams.addExistingPlayer(
          teamId: to.id,
          userId: userId,
          name: name,
          existing: existing,
        );
        continue;
      }
      final auctionPlayer = change['auction_id'] as String?;
      final created = await tournamentTeams.addPlayer(
        player: TournamentTeamPlayer(
          id: '',
          teamId: to.id,
          name: name,
          photoId: change['has_photo'] == true ? auctionPlayer : null,
        ),
        existing: existing,
        createdBy: owner,
      );
      players[cx] = created.id;
    }
  }

  MatchGroup _group(String type) => switch (type) {
        'LEAGUE' => MatchGroup.round,
        'FINAL' => MatchGroup.finals,
        _ => MatchGroup.semifinal,
      };

  int _playoffNumber = 0;

  Future<void> _seedMatch(Map<String, dynamic> m) async {
    final teamA = teamId(m['team_a'] as String);
    final teamB = teamId(m['team_b'] as String);
    final walkover = m['walkover'] == true;
    final xiA = walkover
        ? <String>[]
        : (m['xi_a'] as List).map((p) => players[p]!).toList();
    final xiB = walkover
        ? <String>[]
        : (m['xi_b'] as List).map((p) => players[p]!).toList();
    final group = _group(m['type'] as String);
    final start = DateTime.parse(m['start_at'] as String);

    final matchId = await matches.updateMatch(MatchModel(
      id: '',
      players: [...xiA, ...xiB],
      team_ids: [teamA, teamB],
      team_creator_ids: [owner],
      teams: [
        MatchTeamModel(
          team_id: teamA,
          squad: xiA.map((id) => MatchPlayer(id: id)).toList(),
        ),
        MatchTeamModel(
          team_id: teamB,
          squad: xiB.map((id) => MatchPlayer(id: id)).toList(),
        ),
      ],
      match_type: MatchType.limitedOvers,
      number_of_over: m['overs'] as int,
      over_per_bowler: 2,
      city: '',
      ground: m['venue'] as String,
      match_group: group,
      match_group_number: group == MatchGroup.round ? 1 : ++_playoffNumber,
      tournament_id: tournamentId,
      start_time: start,
      start_at: start,
      updated_at: DateTime.now(),
      created_by: owner,
      ball_type: BallType.leather,
      pitch_type: PitchType.turf,
      match_status: walkover ? MatchStatus.yetToStart : MatchStatus.running,
    ));
    await tournaments.addMatchInTournament(tournamentId, matchId);
    await db.collection('matches').doc(matchId).update({
      'match_number': m['number'],
      'stage': m['stage'],
      'result_margin': m['margin'],
      if (walkover) 'walkover_winner_id': teamId(m['winner'] as String),
    });

    if (walkover) {
      await matches.updateMatchStatus(matchId, MatchStatus.abandoned);
      await _recordWalkover(teamId(m['winner'] as String), teamA, teamB);
      return;
    }

    final tossWinner = teamId(m['toss_winner'] as String);
    final decision =
        m['toss_decision'] == 'bat' ? TossDecision.bat : TossDecision.bowl;
    final inningsData = (m['innings'] as List).cast<Map>();
    final firstBatting = teamId(inningsData.first['batting'] as String);
    await matches.updateTossDetails(
      matchId,
      tossWinner,
      decision,
      firstBatting,
    );

    final opponent = tossWinner == teamA ? teamB : teamA;
    final tossInning = _Inning(InningModel(
      id: innings.generateInningId,
      match_id: matchId,
      team_id: tossWinner,
      index: decision == TossDecision.bat ? 1 : 2,
      innings_status: decision == TossDecision.bat
          ? InningStatus.running
          : InningStatus.yetToStart,
    ));
    final otherInning = _Inning(InningModel(
      id: innings.generateInningId,
      match_id: matchId,
      team_id: opponent,
      index: decision == TossDecision.bat ? 2 : 1,
      innings_status: decision == TossDecision.bat
          ? InningStatus.yetToStart
          : InningStatus.running,
    ));
    await innings.createInnings(
      innings: [tossInning.model, otherInning.model],
    );
    final byTeam = {tossWinner: tossInning, opponent: otherInning};

    final replay = _MatchReplay(this, matchId, [...xiA, ...xiB]);
    for (var i = 0; i < inningsData.length; i++) {
      final data = inningsData[i];
      final batting = byTeam[teamId(data['batting'] as String)]!;
      final bowling = byTeam[teamId(data['bowling'] as String)]!;
      await replay.playInning(
        batting,
        bowling,
        (data['balls'] as List).cast<Map>(),
      );
      if (i == 0) {
        await innings.updateInningsStatuses({
          batting.model.id: InningStatus.finish,
          bowling.model.id: InningStatus.running,
        });
        await matches.updateCurrentPlayingTeam(
          matchId: matchId,
          teamId: bowling.model.team_id,
        );
      } else {
        await innings.updateInningStatus(
          inningId: batting.model.id,
          status: InningStatus.finish,
        );
      }
    }
    await matches.updateMatchStatus(matchId, MatchStatus.finish);
    await replay.finishMatch();
  }

  /// The scoring flow has no walkover; the winner gets the two points.
  Future<void> _recordWalkover(
      String winner, String teamA, String teamB) async {
    final stats =
        db.collection('tournaments').doc(tournamentId).collection('team_stats');
    for (final team in [teamA, teamB]) {
      final won = team == winner;
      await stats.doc(team).set({
        'team_id': team,
        'played_matches': FieldValue.increment(1),
        if (won) 'wins': FieldValue.increment(1),
        if (won) 'points': FieldValue.increment(2),
        if (!won) 'losses': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
  }

  Future<List<Map<String, dynamic>>> export() async {
    final out = <Map<String, dynamic>>[];
    Future<void> collection(String path, {List<String> sub = const []}) async {
      final snapshot = await db.collection(path).get();
      for (final doc in snapshot.docs) {
        out.add({
          'path': '$path/${doc.id}',
          'fields': doc.data().map((k, v) => MapEntry(k, _value(v))),
        });
        for (final name in sub) {
          await collection('$path/${doc.id}/$name');
        }
      }
    }

    await collection('auctions', sub: ['log']);
    await collection('photos');
    await collection('team_pools');
    await collection('teams', sub: ['team_stat']);
    await collection('users', sub: ['user_stat']);
    await collection('tournaments', sub: ['team_stats', 'player_key_stats']);
    await collection('matches', sub: ['match_settings']);
    await collection('innings');
    await collection('ball_scores');
    await collection('match_events');
    await collection('partnerships');
    return out;
  }

  /// Firestore REST value.
  static Map<String, dynamic> _value(Object? v) {
    if (v == null) return {'nullValue': null};
    if (v is bool) return {'booleanValue': v};
    if (v is int) return {'integerValue': '$v'};
    if (v is double) return {'doubleValue': v};
    if (v is String) return {'stringValue': v};
    if (v is Timestamp) {
      return {'timestampValue': v.toDate().toUtc().toIso8601String()};
    }
    if (v is DateTime) return {'timestampValue': v.toUtc().toIso8601String()};
    if (v is Blob) return {'bytesValue': base64Encode(v.bytes)};
    if (v is List) {
      return {
        'arrayValue': {'values': v.map(_value).toList()},
      };
    }
    if (v is Map) {
      return {
        'mapValue': {
          'fields': v.map((k, e) => MapEntry('$k', _value(e))),
        },
      };
    }
    throw UnsupportedError('Unsupported value ${v.runtimeType}');
  }
}

/// Mirrors what the scoring screen writes for each delivery, innings change
/// and match end.
class _MatchReplay {
  final _Seeder s;
  final String matchId;
  final List<String> matchPlayers;
  final allBalls = <BallScoreModel>[];
  final matchEvents = <MatchEventModel>[];

  /// Player id -> performances across innings.
  final performance = <String, List<PlayerPerformance>>{};

  _MatchReplay(this.s, this.matchId, this.matchPlayers);

  Future<void> playInning(
    _Inning batting,
    _Inning bowling,
    List<Map> data,
  ) async {
    final inningId = batting.model.id;
    final teamId = batting.model.team_id;
    final scores = <BallScoreModel>[];
    final atCrease = <String>[];
    var lastIndex = 0;

    for (final raw in data) {
      final striker = s.players[raw['striker']]!;
      final nonStriker = s.players[raw['non_striker']]!;
      final arrivals = <MatchPlayer>[];
      for (final id in [striker, nonStriker]) {
        final list = performance.putIfAbsent(id, () => []);
        if (list.any((p) => p.inning_id == inningId)) continue;
        list.add(PlayerPerformance(
          inning_id: inningId,
          status: PlayerStatus.playing,
          index: ++lastIndex,
        ));
        atCrease.add(id);
        arrivals.add(MatchPlayer(id: id, performance: list.toList()));
      }
      if (arrivals.isNotEmpty) {
        await s.matches.updateTeamsSquad(
          matchId,
          MatchTeamModel(team_id: teamId, squad: arrivals),
        );
      }

      final wicket = raw['wicket'] == null
          ? null
          : WicketType.values.byName(raw['wicket'] as String);
      final extrasType = raw['extra_type'] == null
          ? null
          : ExtrasType.values.byName(raw['extra_type'] as String);
      final out = raw['out'] == null ? null : s.players[raw['out']];
      final at = DateTime.parse(raw['at'] as String);
      final ball = BallScoreModel(
        id: s.balls.generateBallScoreId,
        inning_id: inningId,
        match_id: matchId,
        over_number: raw['over'] as int,
        ball_number: raw['ball'] as int,
        bowler_id: s.players[raw['bowler']]!,
        batsman_id: striker,
        non_striker_id: nonStriker,
        is_four: raw['four'] == true,
        is_six: raw['six'] == true,
        extras_awarded: raw['extras'] as int?,
        extras_type: extrasType,
        player_out_id: out,
        runs_scored: raw['runs'] as int,
        wicket_taker_id: raw['taker'] == null ? null : s.players[raw['taker']],
        wicket_type: wicket,
        time: at,
        score_time: at,
      );

      var wicketCount = bowling.wickets;
      if (wicket != null && wicket != WicketType.retiredHurt) wicketCount++;
      final totalRuns =
          batting.runs + ball.runs_scored + (ball.extras_awarded ?? 0);

      MatchPlayer? outPlayer;
      if (wicket != null && out != null && performance[out] != null) {
        final list = performance[out]!
            .map((p) => p.inning_id == inningId
                ? p.copyWith(
                    status: wicket == WicketType.retiredHurt
                        ? PlayerStatus.injured
                        : PlayerStatus.played,
                  )
                : p)
            .toList();
        performance[out] = list;
        atCrease.remove(out);
        outPlayer = MatchPlayer(id: out, performance: list);
      }

      await _addMatchEvent(ball, scores);
      if (wicket != null) await _addPartnershipIfNeeded(ball, scores);
      await s.balls.addBallScoreAndUpdateTeamDetails(
        score: ball,
        matchId: matchId,
        battingTeamId: teamId,
        battingTeamInningId: inningId,
        totalRuns: totalRuns,
        bowlingTeamId: bowling.model.team_id,
        bowlingTeamInningId: bowling.model.id,
        totalWicketTaken: wicketCount,
        totalBowlingTeamRuns: bowling.runs,
        updatedPlayer: outPlayer,
      );
      batting.runs = totalRuns;
      bowling.wickets = wicketCount;
      scores.add(ball);
    }

    final last = scores.lastWhereOrNull(
      (b) => b.extras_type != ExtrasType.penaltyRun,
    );
    if (last != null && last.wicket_type == null) {
      await _addPartnershipIfNeeded(last, scores.sublist(0, scores.length - 1));
    }
    await _updatePlayerStats(scores);
    if (atCrease.isNotEmpty) {
      final finished = atCrease.map((id) {
        final list = performance[id]!
            .map((p) => p.inning_id == inningId
                ? p.copyWith(status: PlayerStatus.played)
                : p)
            .toList();
        performance[id] = list;
        return MatchPlayer(id: id, performance: list);
      }).toList();
      await s.matches.updateTeamsSquad(
        matchId,
        MatchTeamModel(team_id: teamId, squad: finished),
      );
    }
    allBalls.addAll(scores);
  }

  Future<void> _updatePlayerStats(List<BallScoreModel> scores) async {
    for (final player in matchPlayers) {
      final oldStats = await s.users.getUserStats(player, UserStatType.other);
      final stats = scores
          .where((b) =>
              b.batsman_id == player ||
              b.bowler_id == player ||
              b.wicket_taker_id == player)
          .toList()
          .calculateUserStats(
            player,
            oldUserStats: oldStats,
            type: UserStatType.other,
          );
      await s.users.updateUserStats(player, stats);
    }
  }

  Future<void> finishMatch() async {
    final match = await s.matches.getMatchById(matchId);
    for (final team in match.teams) {
      final current = await s.teams.getTeamStatById(team.team_id);
      await s.teams.updateTeamStat(
        team.team_id,
        match.updateTeamStat(team.team_id, current),
      );
    }
    await s.tournaments.updateTournamentStats(
      tournamentId: s.tournamentId,
      match: match.copyWith(match_status: MatchStatus.finish),
      ballScores: allBalls,
    );
  }

  Future<void> _saveEvent(MatchEventModel event) async {
    await s.events.updateMatchEvent(event);
    matchEvents.removeWhere((e) => e.id == event.id);
    matchEvents.add(event);
  }

  Future<void> _addMatchEvent(
    BallScoreModel ball,
    List<BallScoreModel> scores,
  ) async {
    if (ball.is_four || ball.is_six) {
      await _saveEvent(MatchEventModel(
        id: s.events.generateMatchEventId,
        match_id: ball.match_id,
        inning_id: ball.inning_id,
        type: ball.is_six ? EventType.six : EventType.four,
        bowler_id: ball.bowler_id,
        batsman_id: ball.batsman_id,
        over: ball.formattedOver,
        time: ball.score_time ?? DateTime.now(),
        ball_ids: [ball.id],
      ));
    } else if (ball.wicket_type != null) {
      await _addWicketEvent(ball, scores);
    }
    await _addMilestoneEvent(ball, scores);
  }

  Future<void> _addWicketEvent(
    BallScoreModel ball,
    List<BallScoreModel> scores,
  ) async {
    final lastBall = scores.lastWhereOrNull(
      (b) =>
          b.wicket_type != WicketType.retired &&
          b.wicket_type != WicketType.retiredHurt &&
          b.wicket_type != WicketType.timedOut,
    );
    MatchEventModel event = MatchEventModel(
      id: s.events.generateMatchEventId,
      match_id: ball.match_id,
      inning_id: ball.inning_id,
      type: EventType.wicket,
      bowler_id: ball.bowler_id,
      time: ball.score_time ?? DateTime.now(),
    );
    if (lastBall?.wicket_type != null &&
        lastBall?.bowler_id == ball.bowler_id) {
      event = matchEvents.firstWhereOrNull((e) =>
              (e.type == EventType.wicket || e.type == EventType.hatTrick) &&
              e.bowler_id == ball.bowler_id &&
              e.ball_ids.contains(lastBall?.id)) ??
          event;
    }
    final wickets = event.wickets.toList()
      ..add(MatchEventWicket(
        time: ball.score_time ?? DateTime.now(),
        ball_id: ball.id,
        batsman_id: ball.player_out_id ?? ball.batsman_id,
        wicket_type: ball.wicket_type!,
        over: ball.formattedOver,
      ));
    await _saveEvent(event.copyWith(
      ball_ids: wickets.map((w) => w.ball_id).toList(),
      type: wickets.length == 1 ? EventType.wicket : EventType.hatTrick,
      wickets: wickets,
    ));
  }

  Future<void> _addMilestoneEvent(
    BallScoreModel ball,
    List<BallScoreModel> scores,
  ) async {
    final playerId = ball.batsman_id;
    final before = scores.calculateBattingStats(playerId).run_scored;
    final after = [...scores, ball].calculateBattingStats(playerId);
    if (!((before < 50 && after.run_scored >= 50) ||
        (before < 100 && after.run_scored >= 100))) {
      return;
    }
    final existing = matchEvents.firstWhereOrNull((e) =>
        (e.type == EventType.fifty || e.type == EventType.century) &&
        e.batsman_id == playerId &&
        e.inning_id == ball.inning_id);
    final milestones = existing?.milestone.toList() ?? []
      ..add(MatchEventMilestone(
        time: ball.score_time ?? DateTime.now(),
        runs: after.run_scored,
        over: ball.formattedOver,
        ball_faced: after.ball_faced,
        fours: after.fours,
        sixes: after.sixes,
        ball_id: ball.id,
      ));
    await _saveEvent(MatchEventModel(
      id: existing?.id ?? s.events.generateMatchEventId,
      match_id: ball.match_id,
      inning_id: ball.inning_id,
      type: after.run_scored >= 100 ? EventType.century : EventType.fifty,
      batsman_id: playerId,
      ball_ids: milestones.map((m) => m.ball_id).toList(),
      milestone: milestones,
      time: ball.score_time ?? DateTime.now(),
    ));
  }

  Future<void> _addPartnershipIfNeeded(
    BallScoreModel ball,
    List<BallScoreModel> previous,
  ) async {
    final batsmen = [ball.batsman_id, ball.non_striker_id];
    final scores = previous
        .where((b) =>
            batsmen.contains(b.batsman_id) &&
            batsmen.contains(b.non_striker_id))
        .toList()
      ..add(ball);

    var totalRuns = 0;
    var extras = 0;
    var ballFaced = 0;
    for (final b in scores) {
      totalRuns += (b.extras_awarded ?? 0) + b.runs_scored;
      if ((b.extras_type == null ||
              b.extras_type == ExtrasType.legBye ||
              b.extras_type == ExtrasType.bye) &&
          b.wicket_type != WicketType.retired &&
          b.wicket_type != WicketType.retiredHurt &&
          b.wicket_type != WicketType.timedOut) {
        ballFaced++;
      }
      extras += b.extras_awarded ?? 0;
    }
    if (totalRuns <= 50) return;

    scores.sort((a, b) => (a.score_time ?? DateTime.now())
        .compareTo(b.score_time ?? DateTime.now()));
    await s.partnerships.updatePartnership(PartnershipModel(
      id: s.partnerships.generatePartnershipId,
      match_id: ball.match_id,
      inning_id: ball.inning_id,
      player_ids: batsmen,
      players: batsmen.map((id) {
        final stat = scores.calculateBattingStats(id);
        return PartnershipPlayer(
          player_id: id,
          sixes: stat.sixes,
          fours: stat.fours,
          runs: stat.run_scored,
          ball_faced: stat.ball_faced,
        );
      }).toList(),
      runs: totalRuns,
      extras: extras,
      ball_faced: ballFaced,
      start_over: scores.first.formattedOver,
      end_over: scores.last.formattedOver,
    ));
  }
}
