import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../api/match/match_model.dart';
import '../../api/team/team_model.dart';
import 'pocketbase_config.dart';

final pocketBaseMatchServiceProvider = Provider<PocketBaseMatchService>(
  (ref) => PocketBaseMatchService(PocketBase(PocketBaseConfig.url)),
);

/// Reads live matches from PocketBase. Writes/scoring UI come in later slices.
class PocketBaseMatchService {
  PocketBaseMatchService(this._pb);

  final PocketBase _pb;

  static const idPrefix = 'pb_';

  bool get enabled => PocketBaseConfig.scoringEnabled;

  Stream<List<MatchModel>> streamLiveMatches() {
    if (!enabled) {
      return Stream.value(const []);
    }

    final controller = StreamController<List<MatchModel>>();
    UnsubscribeFunc? unsubscribe;
    Timer? poll;

    Future<void> refresh() async {
      if (controller.isClosed) return;
      try {
        // PB 0.40 rejects sort on system `created`/`updated` for this
        // collection; `start_at` is a real date field and works.
        final result = await _pb.collection('matches').getList(
              page: 1,
              perPage: 50,
              filter: 'match_status = 2',
              sort: '-start_at',
            );
        if (!controller.isClosed) {
          controller.add(result.items.map(_toMatch).toList());
        }
      } catch (e) {
        // ignore: avoid_print
        print('PocketBaseMatchService.refresh failed: $e');
        if (!controller.isClosed) controller.add(const []);
      }
    }

    controller.onListen = () async {
      await refresh();
      try {
        unsubscribe = await _pb.collection('matches').subscribe(
          '*',
          (_) => refresh(),
        );
      } catch (_) {
        poll = Timer.periodic(const Duration(seconds: 8), (_) => refresh());
      }
    };

    controller.onCancel = () async {
      poll?.cancel();
      if (unsubscribe != null) await unsubscribe!();
    };

    return controller.stream;
  }

  MatchModel _toMatch(RecordModel r) {
    final teamAId = () {
      final v = r.getStringValue('team_a_id');
      return v.isNotEmpty ? v : 'a_${r.id}';
    }();
    final teamBId = () {
      final v = r.getStringValue('team_b_id');
      return v.isNotEmpty ? v : 'b_${r.id}';
    }();
    final teamAName = r.getStringValue('team_a_name', 'Team A');
    final teamBName = r.getStringValue('team_b_name', 'Team B');

    MatchTeamModel team({
      required String id,
      required String name,
      required int runs,
      required int wickets,
      required double overs,
    }) {
      return MatchTeamModel(
        team_id: id,
        run: runs,
        wicket: wickets,
        over: overs,
        team: TeamModel(
          id: id,
          name: name,
          name_lowercase: name.toLowerCase(),
        ),
      );
    }

    final statusVal = r.getIntValue('match_status', 2);
    final status = MatchStatus.values.firstWhere(
      (s) => s.value == statusVal,
      orElse: () => MatchStatus.running,
    );

    TossDecision? toss;
    final td = r.get<num?>('toss_decision');
    if (td != null) {
      toss = TossDecision.values.firstWhere(
        (e) => e.value == td.toInt(),
        orElse: () => TossDecision.bat,
      );
    }

    return MatchModel(
      id: '$idPrefix${r.id}',
      teams: [
        team(
          id: teamAId,
          name: teamAName,
          runs: r.getIntValue('team_a_runs'),
          wickets: r.getIntValue('team_a_wickets'),
          overs: r.getDoubleValue('team_a_overs'),
        ),
        team(
          id: teamBId,
          name: teamBName,
          runs: r.getIntValue('team_b_runs'),
          wickets: r.getIntValue('team_b_wickets'),
          overs: r.getDoubleValue('team_b_overs'),
        ),
      ],
      match_type: MatchType.limitedOvers,
      number_of_over: r.getIntValue('number_of_over', 5),
      over_per_bowler: 2,
      team_ids: [teamAId, teamBId],
      city: r.getStringValue('city'),
      ground: r.getStringValue('ground'),
      ball_type: BallType.leather,
      pitch_type: PitchType.turf,
      created_by: r.getStringValue('created_by'),
      match_status: status,
      toss_winner_id: r.get<String?>('toss_winner_id'),
      toss_decision: toss,
      current_playing_team_id: r.get<String?>('current_playing_team_id'),
      umpire_ids: const [],
      scorer_ids: _stringList(r.get<dynamic>('scorer_ids')),
      commentator_ids: const [],
    );
  }

  List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static bool isPocketBaseMatchId(String id) => id.startsWith(idPrefix);
}
