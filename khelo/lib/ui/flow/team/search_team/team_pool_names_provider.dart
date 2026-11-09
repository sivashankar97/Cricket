import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _userTournamentTeamsProvider =
    StreamProvider.autoDispose<List<TournamentTeam>>((ref) {
  final userId = ref.watch(currentUserPod)?.id;
  if (userId == null) return Stream.value(const []);
  return ref.read(tournamentTeamServiceProvider).streamTeams(userId);
});

final _userTeamPoolsProvider =
    StreamProvider.autoDispose<List<TeamPool>>((ref) {
  final userId = ref.watch(currentUserPod)?.id;
  if (userId == null) return Stream.value(const []);
  return ref.read(tournamentTeamServiceProvider).streamPools(userId);
});

/// Team id → name of the tournament team pool (e.g. "GCPL Teams") it is in.
final teamPoolNamesProvider = Provider.autoDispose<Map<String, String>>((ref) {
  final teams = ref.watch(_userTournamentTeamsProvider).valueOrNull ?? const [];
  final pools = ref.watch(_userTeamPoolsProvider).valueOrNull ?? const [];
  final poolNames = {for (final pool in pools) pool.id: pool.name};
  return {
    for (final team in teams)
      if (poolNames[team.poolId] != null) team.id: poolNames[team.poolId]!,
  };
});
