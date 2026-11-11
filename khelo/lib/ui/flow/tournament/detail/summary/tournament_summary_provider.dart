import 'package:data/api/ball_score/ball_score_model.dart';
import 'package:data/api/match/match_model.dart';
import 'package:data/api/tournament/tournament_extras.dart';
import 'package:data/service/ball_score/ball_score_service.dart';
import 'package:data/service/tournament/tournament_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tournament_detail_view_model.dart';
import 'tournament_summary.dart';

String _key(Iterable<String> ids) => (ids.toSet().toList()..sort()).join(',');

List<String> _ids(String key) => key.isEmpty ? [] : key.split(',');

/// Keyed by the finished match ids, so live score updates don't reload the
/// balls of every finished match.
final _ballsProvider = FutureProvider.autoDispose
    .family<List<BallScoreModel>, String>((ref, key) =>
        ref.read(ballScoreServiceProvider).getBallScoresByMatchIds(_ids(key)));

final _matchExtrasProvider = FutureProvider.autoDispose
    .family<Map<String, MatchExtras>, String>((ref, key) =>
        ref.read(tournamentServiceProvider).getMatchExtras(_ids(key)));

final _teamExtrasProvider = FutureProvider.autoDispose
    .family<Map<String, TeamExtras>, String>((ref, key) =>
        ref.read(tournamentServiceProvider).getTeamExtras(_ids(key)));

final _matchesProvider = Provider.autoDispose<List<MatchModel>>(
  (ref) => ref.watch(tournamentDetailStateProvider.select((s) => s.matches)),
);

final tournamentMatchExtrasProvider =
    Provider.autoDispose<Map<String, MatchExtras>>((ref) {
  final matches = ref.watch(_matchesProvider);
  return ref
          .watch(_matchExtrasProvider(_key(matches.map((m) => m.id))))
          .valueOrNull ??
      const {};
});

final tournamentTeamExtrasProvider =
    Provider.autoDispose<Map<String, TeamExtras>>((ref) {
  final teams = ref.watch(
      tournamentDetailStateProvider.select((s) => s.tournament?.teams ?? []));
  return ref
          .watch(_teamExtrasProvider(_key(teams.map((t) => t.id))))
          .valueOrNull ??
      const {};
});

final _photoIdsProvider = FutureProvider.autoDispose
    .family<Map<String, String>, String>((ref, key) =>
        ref.read(tournamentServiceProvider).getUserPhotoIds(_ids(key)));

/// Auction `photo_id` per player id, for everyone in a match squad.
final tournamentPlayerPhotosProvider =
    Provider.autoDispose<Map<String, String>>((ref) {
  final matches = ref.watch(_matchesProvider);
  final ids = [
    for (final match in matches)
      for (final side in match.teams)
        for (final player in side.squad) player.id,
  ];
  return ref.watch(_photoIdsProvider(_key(ids))).valueOrNull ?? const {};
});

/// True while the ball-by-ball data for the stats is still loading.
final tournamentSummaryLoadingProvider = Provider.autoDispose<bool>((ref) {
  final matches = ref.watch(_matchesProvider);
  final key = _key(matches
      .where((m) => m.match_status == MatchStatus.finish)
      .map((m) => m.id));
  return ref.watch(_ballsProvider(key)).isLoading;
});

final tournamentSummaryProvider =
    Provider.autoDispose<TournamentSummary>((ref) {
  final teams = ref.watch(
      tournamentDetailStateProvider.select((s) => s.tournament?.teams ?? []));
  final matches = ref.watch(_matchesProvider);
  final key = _key(matches
      .where((m) => m.match_status == MatchStatus.finish)
      .map((m) => m.id));
  final balls = ref.watch(_ballsProvider(key)).valueOrNull ?? const [];
  return TournamentSummary.build(
    teams: teams,
    matches: matches,
    balls: balls,
    matchExtras: ref.watch(tournamentMatchExtrasProvider),
  );
});
