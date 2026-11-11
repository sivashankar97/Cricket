import 'package:collection/collection.dart';
import 'package:data/api/ball_score/ball_score_model.dart';
import 'package:data/api/match/match_model.dart';
import 'package:data/api/team/team_model.dart';
import 'package:data/api/tournament/tournament_extras.dart';
import 'package:data/api/user/user_models.dart';

/// Result of one match for one team, used for form guides.
enum FormResult { win, loss, tie, noResult }

class StandingRow {
  final TeamModel team;
  final int played;
  final int won;
  final int lost;
  final int tied;
  final int noResult;
  final int points;
  final double nrr;

  /// Oldest first, last five.
  final List<FormResult> form;

  const StandingRow({
    required this.team,
    required this.played,
    required this.won,
    required this.lost,
    required this.tied,
    required this.noResult,
    required this.points,
    required this.nrr,
    required this.form,
  });
}

class SummaryPlayer {
  final UserModel user;
  final TeamModel team;

  const SummaryPlayer(this.user, this.team);

  String get id => user.id;
}

class BattingInnings {
  final SummaryPlayer player;
  final String matchId;
  final int runs;
  final int balls;
  final bool out;

  const BattingInnings({
    required this.player,
    required this.matchId,
    required this.runs,
    required this.balls,
    required this.out,
  });
}

class BattingRow {
  final SummaryPlayer player;
  final int innings;
  final int runs;
  final int balls;
  final int outs;
  final int fours;
  final int sixes;
  final int fifties;
  final int hundreds;
  final int highest;
  final bool highestNotOut;

  const BattingRow({
    required this.player,
    required this.innings,
    required this.runs,
    required this.balls,
    required this.outs,
    required this.fours,
    required this.sixes,
    required this.fifties,
    required this.hundreds,
    required this.highest,
    required this.highestNotOut,
  });

  double? get average => outs == 0 ? null : runs / outs;

  double get strikeRate => balls == 0 ? 0 : runs * 100 / balls;
}

class BowlingRow {
  final SummaryPlayer player;
  final int balls;
  final int maidens;
  final int runs;
  final int wickets;
  final int bestWickets;
  final int bestRuns;

  const BowlingRow({
    required this.player,
    required this.balls,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.bestWickets,
    required this.bestRuns,
  });

  String get overs => '${balls ~/ 6}.${balls % 6}';

  double get economy => balls == 0 ? 0 : runs * 6 / balls;
}

class FieldingRow {
  final SummaryPlayer player;
  final int catches;
  final int runOuts;
  final int stumpings;

  const FieldingRow({
    required this.player,
    required this.catches,
    required this.runOuts,
    required this.stumpings,
  });

  int get total => catches + runOuts + stumpings;
}

/// Points: run + 1 per four + 2 per six + 10 per fifty (batting);
/// 20 per wicket + 10 per maiden (bowling); 8 per catch, 10 per run out or
/// stumping (fielding).
class MvpRow {
  final SummaryPlayer player;
  final int batting;
  final int bowling;
  final int fielding;

  const MvpRow({
    required this.player,
    required this.batting,
    required this.bowling,
    required this.fielding,
  });

  int get total => batting + bowling + fielding;
}

class TournamentSummary {
  final List<StandingRow> standings;
  final List<BattingRow> batting;
  final List<BattingInnings> innings;
  final List<BowlingRow> bowling;
  final List<FieldingRow> fielding;
  final List<MvpRow> mvp;

  const TournamentSummary({
    this.standings = const [],
    this.batting = const [],
    this.innings = const [],
    this.bowling = const [],
    this.fielding = const [],
    this.mvp = const [],
  });

  StandingRow? standingOf(String teamId) =>
      standings.firstWhereOrNull((row) => row.team.id == teamId);

  int rankOf(String teamId) =>
      standings.indexWhere((row) => row.team.id == teamId) + 1;

  factory TournamentSummary.build({
    required List<TeamModel> teams,
    required List<MatchModel> matches,
    required List<BallScoreModel> balls,
    Map<String, MatchExtras> matchExtras = const {},
  }) {
    final players = <String, SummaryPlayer>{};
    for (final match in matches) {
      for (final side in match.teams) {
        for (final p in side.squad) {
          players[p.id] = SummaryPlayer(p.player, side.team);
        }
      }
    }
    final finished = matches
        .where((m) => m.match_status == MatchStatus.finish)
        .map((m) => m.id)
        .toSet();
    final scored = balls
        .where((b) =>
            finished.contains(b.match_id) &&
            b.extras_type != ExtrasType.penaltyRun)
        .sortedBy<DateTime>((b) =>
            b.score_time ?? b.time ?? DateTime.fromMillisecondsSinceEpoch(0));

    final batting = _batting(scored, players);
    final bowling = _bowling(scored, players);
    final fielding = _fielding(scored, players);
    return TournamentSummary(
      standings: _standings(teams, matches, matchExtras),
      batting: batting.rows,
      innings: batting.innings,
      bowling: bowling,
      fielding: fielding,
      mvp: _mvp(players, batting.rows, bowling, fielding),
    );
  }

  static int _oversToBalls(double overs) {
    final whole = overs.floor();
    return whole * 6 + ((overs - whole) * 10).round();
  }

  static List<StandingRow> _standings(
    List<TeamModel> teams,
    List<MatchModel> matches,
    Map<String, MatchExtras> extras,
  ) {
    final results = <String, List<(DateTime, FormResult)>>{};
    final runsFor = <String, int>{};
    final ballsFor = <String, int>{};
    final runsAgainst = <String, int>{};
    final ballsAgainst = <String, int>{};

    void add(String teamId, DateTime at, FormResult result) =>
        results.putIfAbsent(teamId, () => []).add((at, result));

    for (final match in matches) {
      if (match.teams.length != 2) continue;
      final at = match.start_at ?? match.start_time ?? DateTime(2000);
      final ids = match.teams.map((t) => t.team_id).toList();
      final walkover = extras[match.id]?.walkoverWinnerId;
      if (match.match_status == MatchStatus.abandoned) {
        for (final id in ids) {
          add(
            id,
            at,
            walkover == null
                ? FormResult.noResult
                : (id == walkover ? FormResult.win : FormResult.loss),
          );
        }
        continue;
      }
      if (match.match_status != MatchStatus.finish) continue;
      final result = match.matchResult;
      if (result == null) continue;
      for (final id in ids) {
        add(
          id,
          at,
          result.winType == WinnerByType.tie
              ? FormResult.tie
              : (id == result.teamId ? FormResult.win : FormResult.loss),
        );
      }
      final quota = match.number_of_over * 6;
      for (final side in match.teams) {
        final other = match.teams.firstWhere((t) => t != side);
        final allOut =
            side.squad.length > 1 && other.wicket >= side.squad.length - 1;
        final faced = allOut ? quota : _oversToBalls(side.over);
        runsFor.update(side.team_id, (v) => v + side.run,
            ifAbsent: () => side.run);
        ballsFor.update(side.team_id, (v) => v + faced, ifAbsent: () => faced);
        runsAgainst.update(other.team_id, (v) => v + side.run,
            ifAbsent: () => side.run);
        ballsAgainst.update(other.team_id, (v) => v + faced,
            ifAbsent: () => faced);
      }
    }

    double rate(int runs, int balls) => balls == 0 ? 0 : runs * 6 / balls;

    final rows = teams.map((team) {
      final list = (results[team.id] ?? [])
        ..sort((a, b) => a.$1.compareTo(b.$1));
      final form = list.map((r) => r.$2).toList();
      int count(FormResult r) => form.where((f) => f == r).length;
      final won = count(FormResult.win);
      final tied = count(FormResult.tie);
      final noResult = count(FormResult.noResult);
      return StandingRow(
        team: team,
        played: form.length,
        won: won,
        lost: count(FormResult.loss),
        tied: tied,
        noResult: noResult,
        points: won * 2 + tied + noResult,
        nrr: rate(runsFor[team.id] ?? 0, ballsFor[team.id] ?? 0) -
            rate(runsAgainst[team.id] ?? 0, ballsAgainst[team.id] ?? 0),
        form: form.length > 5 ? form.sublist(form.length - 5) : form,
      );
    }).toList()
      ..sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        if (byPoints != 0) return byPoints;
        final byNrr = b.nrr.compareTo(a.nrr);
        return byNrr != 0 ? byNrr : a.team.name.compareTo(b.team.name);
      });
    return rows;
  }

  static bool _isOut(BallScoreModel b, String playerId) =>
      b.player_out_id == playerId &&
      b.wicket_type != null &&
      b.wicket_type != WicketType.retiredHurt;

  static ({List<BattingRow> rows, List<BattingInnings> innings}) _batting(
    List<BallScoreModel> balls,
    Map<String, SummaryPlayer> players,
  ) {
    final byInning = groupBy(balls, (BallScoreModel b) => b.inning_id);
    final innings = <BattingInnings>[];
    final fours = <String, int>{};
    final sixes = <String, int>{};
    for (final entry in byInning.entries) {
      final ids = <String>{
        for (final b in entry.value) ...[
          b.batsman_id,
          if (b.non_striker_id.isNotEmpty) b.non_striker_id,
        ],
      };
      for (final id in ids) {
        final player = players[id];
        if (player == null) continue;
        var runs = 0;
        var faced = 0;
        for (final b in entry.value.where((b) => b.batsman_id == id)) {
          runs += b.runs_scored;
          if (b.extras_type != ExtrasType.wide &&
              b.wicket_type != WicketType.retiredHurt &&
              b.wicket_type != WicketType.retired) {
            faced++;
          }
          if (b.is_four) fours[id] = (fours[id] ?? 0) + 1;
          if (b.is_six) sixes[id] = (sixes[id] ?? 0) + 1;
        }
        innings.add(BattingInnings(
          player: player,
          matchId: entry.value.first.match_id,
          runs: runs,
          balls: faced,
          out: entry.value.any((b) => _isOut(b, id)),
        ));
      }
    }

    final rows = groupBy(innings, (BattingInnings i) => i.player.id)
        .entries
        .map((entry) {
      final list = entry.value;
      final best = list.reduce((a, b) =>
          b.runs > a.runs || (b.runs == a.runs && !b.out && a.out) ? b : a);
      return BattingRow(
        player: list.first.player,
        innings: list.length,
        runs: list.map((i) => i.runs).sum,
        balls: list.map((i) => i.balls).sum,
        outs: list.where((i) => i.out).length,
        fours: fours[entry.key] ?? 0,
        sixes: sixes[entry.key] ?? 0,
        fifties: list.where((i) => i.runs >= 50 && i.runs < 100).length,
        hundreds: list.where((i) => i.runs >= 100).length,
        highest: best.runs,
        highestNotOut: !best.out,
      );
    }).toList()
      ..sort((a, b) {
        final byRuns = b.runs.compareTo(a.runs);
        return byRuns != 0 ? byRuns : b.strikeRate.compareTo(a.strikeRate);
      });
    return (rows: rows, innings: innings);
  }

  static bool _isDelivery(BallScoreModel b) =>
      b.extras_type != ExtrasType.wide &&
      b.extras_type != ExtrasType.noBall &&
      b.wicket_type != WicketType.retired &&
      b.wicket_type != WicketType.retiredHurt &&
      b.wicket_type != WicketType.timedOut;

  static int _conceded(BallScoreModel b) =>
      b.runs_scored +
      (b.extras_type == ExtrasType.wide || b.extras_type == ExtrasType.noBall
          ? b.extras_awarded ?? 0
          : 0);

  static List<BowlingRow> _bowling(
    List<BallScoreModel> balls,
    Map<String, SummaryPlayer> players,
  ) {
    final rows = <BowlingRow>[];
    for (final entry
        in groupBy(balls, (BallScoreModel b) => b.bowler_id).entries) {
      final player = players[entry.key];
      if (player == null) continue;
      final list = entry.value;
      final overs = groupBy(
          list, (BallScoreModel b) => '${b.inning_id}/${b.over_number}');
      final maidens = overs.values
          .where((o) =>
              o.where(_isDelivery).length >= 6 && o.map(_conceded).sum == 0)
          .length;
      bool credited(BallScoreModel b) =>
          b.wicket_type?.isCreditedToBowler ?? false;
      final spells =
          groupBy(list, (BallScoreModel b) => b.inning_id).values.map(
                (spell) => (
                  spell.where(credited).length,
                  spell.map(_conceded).sum,
                ),
              );
      final best = spells.reduce(
          (a, b) => b.$1 > a.$1 || (b.$1 == a.$1 && b.$2 < a.$2) ? b : a);
      rows.add(BowlingRow(
        player: player,
        balls: list.where(_isDelivery).length,
        maidens: maidens,
        runs: list.map(_conceded).sum,
        wickets: list.where(credited).length,
        bestWickets: best.$1,
        bestRuns: best.$2,
      ));
    }
    rows.sort((a, b) {
      final byWickets = b.wickets.compareTo(a.wickets);
      return byWickets != 0 ? byWickets : a.economy.compareTo(b.economy);
    });
    return rows;
  }

  static List<FieldingRow> _fielding(
    List<BallScoreModel> balls,
    Map<String, SummaryPlayer> players,
  ) {
    final catches = <String, int>{};
    final runOuts = <String, int>{};
    final stumpings = <String, int>{};
    for (final b in balls) {
      final fielder = b.wicket_type == WicketType.caughtAndBowled
          ? b.bowler_id
          : b.wicket_taker_id;
      if (fielder == null) continue;
      final map = switch (b.wicket_type) {
        WicketType.caught ||
        WicketType.caughtBehind ||
        WicketType.caughtAndBowled =>
          catches,
        WicketType.runOut => runOuts,
        WicketType.stumped => stumpings,
        _ => null,
      };
      if (map != null) map[fielder] = (map[fielder] ?? 0) + 1;
    }
    final ids = {...catches.keys, ...runOuts.keys, ...stumpings.keys};
    return ids
        .where(players.containsKey)
        .map((id) => FieldingRow(
              player: players[id]!,
              catches: catches[id] ?? 0,
              runOuts: runOuts[id] ?? 0,
              stumpings: stumpings[id] ?? 0,
            ))
        .toList()
      ..sort((a, b) {
        final byTotal = b.total.compareTo(a.total);
        return byTotal != 0 ? byTotal : b.catches.compareTo(a.catches);
      });
  }

  static List<MvpRow> _mvp(
    Map<String, SummaryPlayer> players,
    List<BattingRow> batting,
    List<BowlingRow> bowling,
    List<FieldingRow> fielding,
  ) {
    final bat = {for (final r in batting) r.player.id: r};
    final bowl = {for (final r in bowling) r.player.id: r};
    final field = {for (final r in fielding) r.player.id: r};
    final ids = {...bat.keys, ...bowl.keys, ...field.keys};
    return ids
        .map((id) {
          final b = bat[id];
          final w = bowl[id];
          final f = field[id];
          return MvpRow(
            player: players[id]!,
            batting: b == null
                ? 0
                : b.runs +
                    b.fours +
                    b.sixes * 2 +
                    (b.fifties + b.hundreds) * 10,
            bowling: w == null ? 0 : w.wickets * 20 + w.maidens * 10,
            fielding:
                f == null ? 0 : f.catches * 8 + (f.runOuts + f.stumpings) * 10,
          );
        })
        .where((r) => r.total > 0)
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }
}
