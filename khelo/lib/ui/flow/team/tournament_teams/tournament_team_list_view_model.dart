import 'dart:async';

import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Teams of one pool; a null pool id lists the ungrouped teams.
final tournamentTeamListStateProvider = StateNotifierProvider.autoDispose
    .family<TournamentTeamListViewNotifier, TournamentTeamListState, String?>(
        (ref, poolId) {
  final notifier = TournamentTeamListViewNotifier(
    ref.read(tournamentTeamServiceProvider),
    poolId,
    ref.read(currentUserPod)?.id,
  );
  ref.listen(currentUserPod, (_, next) => notifier.setUserId(next?.id));
  return notifier;
});

class TournamentTeamListViewNotifier
    extends StateNotifier<TournamentTeamListState> {
  final TournamentTeamService _service;
  StreamSubscription? _teamSubscription;
  StreamSubscription? _poolSubscription;

  TournamentTeamListViewNotifier(this._service, String? poolId, String? userId)
      : super(TournamentTeamListState(poolId: poolId)) {
    setUserId(userId);
  }

  void setUserId(String? userId) {
    if (userId == state.currentUserId && _teamSubscription != null) return;
    state = state.copyWith(currentUserId: userId);
    load();
  }

  void load() {
    _teamSubscription?.cancel();
    _poolSubscription?.cancel();
    final userId = state.currentUserId;
    if (userId == null) {
      state = state.copyWith(loading: false, teams: []);
      return;
    }
    state = state.copyWith(loading: true, error: null);
    final poolId = state.poolId;
    final teams = poolId == null
        ? _service.streamTeams(userId)
        : _service.streamTeamsInPool(poolId);
    _teamSubscription = teams.listen(
      (teams) => state = state.copyWith(teams: teams, loading: false),
      onError: _onError,
    );
    _poolSubscription = _service.streamPools(userId).listen(
      (pools) => state = state.copyWith(pools: pools),
      onError: _onError,
    );
  }

  void _onError(Object error) {
    state = state.copyWith(loading: false, error: error);
    debugPrint('TournamentTeamListViewNotifier: load error -> $error');
  }

  void onSearch(String query) => state = state.copyWith(query: query);

  Future<int> usageCount(TournamentTeam team) =>
      _service.tournamentUsageCount(team.id);

  Future<void> deleteTeam(TournamentTeam team) async {
    try {
      state = state.copyWith(actionError: null);
      await _service.deleteTeam(team);
    } catch (error) {
      state = state.copyWith(actionError: error);
      debugPrint('TournamentTeamListViewNotifier: delete error -> $error');
    }
  }

  Future<void> moveTeam(TournamentTeam team, TeamPool pool) async {
    try {
      state = state.copyWith(actionError: null);
      await _service.moveTeamToPool(team, pool.id);
    } catch (error) {
      state = state.copyWith(actionError: error);
      debugPrint('TournamentTeamListViewNotifier: move error -> $error');
    }
  }

  @override
  void dispose() {
    _teamSubscription?.cancel();
    _poolSubscription?.cancel();
    super.dispose();
  }
}

class TournamentTeamListState {
  final String? poolId;
  final List<TournamentTeam> teams;
  final List<TeamPool> pools;
  final String query;
  final bool loading;
  final Object? error;
  final Object? actionError;
  final String? currentUserId;

  const TournamentTeamListState({
    this.poolId,
    this.teams = const [],
    this.pools = const [],
    this.query = '',
    this.loading = true,
    this.error,
    this.actionError,
    this.currentUserId,
  });

  TeamPool? get pool => pools.where((pool) => pool.id == poolId).firstOrNull;

  /// For the ungrouped list, teams whose pool no longer exists are included.
  List<TournamentTeam> get poolTeams {
    if (poolId != null) return teams;
    final poolIds = pools.map((pool) => pool.id).toSet();
    return teams
        .where((team) => team.poolId == null || !poolIds.contains(team.poolId))
        .toList();
  }

  List<TournamentTeam> get filteredTeams => filterTeams(poolTeams, query);

  TournamentTeamListState copyWith({
    List<TournamentTeam>? teams,
    List<TeamPool>? pools,
    String? query,
    bool? loading,
    Object? error = _unset,
    Object? actionError = _unset,
    String? currentUserId,
  }) =>
      TournamentTeamListState(
        poolId: poolId,
        teams: teams ?? this.teams,
        pools: pools ?? this.pools,
        query: query ?? this.query,
        loading: loading ?? this.loading,
        error: error == _unset ? this.error : error,
        actionError: actionError == _unset ? this.actionError : actionError,
        currentUserId: currentUserId ?? this.currentUserId,
      );
}

const _unset = Object();

List<TournamentTeam> filterTeams(List<TournamentTeam> teams, String query) {
  final key = query.trim().toLowerCase();
  if (key.isEmpty) return teams;
  return teams
      .where((team) =>
          team.name.toLowerCase().contains(key) ||
          (team.shortName?.toLowerCase().contains(key) ?? false))
      .toList();
}
