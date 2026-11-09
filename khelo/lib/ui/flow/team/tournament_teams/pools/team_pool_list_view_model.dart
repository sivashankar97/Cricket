import 'dart:async';

import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teamPoolListStateProvider = StateNotifierProvider.autoDispose<
    TeamPoolListViewNotifier, TeamPoolListState>((ref) {
  final notifier = TeamPoolListViewNotifier(
    ref.read(tournamentTeamServiceProvider),
    ref.read(currentUserPod)?.id,
  );
  ref.listen(currentUserPod, (_, next) => notifier.setUserId(next?.id));
  return notifier;
});

class TeamPoolListViewNotifier extends StateNotifier<TeamPoolListState> {
  final TournamentTeamService _service;
  StreamSubscription? _poolSubscription;
  StreamSubscription? _teamSubscription;
  bool _poolsLoaded = false;
  bool _teamsLoaded = false;

  TeamPoolListViewNotifier(this._service, String? userId)
      : super(const TeamPoolListState()) {
    setUserId(userId);
  }

  void setUserId(String? userId) {
    if (userId == state.currentUserId && _poolSubscription != null) return;
    state = state.copyWith(currentUserId: userId);
    load();
  }

  void load() {
    _poolSubscription?.cancel();
    _teamSubscription?.cancel();
    final userId = state.currentUserId;
    if (userId == null) {
      state = state.copyWith(loading: false, pools: [], teams: []);
      return;
    }
    _poolsLoaded = false;
    _teamsLoaded = false;
    state = state.copyWith(loading: true, error: null);
    _poolSubscription = _service.streamPools(userId).listen(
      (pools) {
        _poolsLoaded = true;
        state = state.copyWith(pools: pools, loading: !_teamsLoaded);
      },
      onError: _onError,
    );
    _teamSubscription = _service.streamTeams(userId).listen(
      (teams) {
        _teamsLoaded = true;
        state = state.copyWith(teams: teams, loading: !_poolsLoaded);
      },
      onError: _onError,
    );
  }

  void _onError(Object error) {
    state = state.copyWith(loading: false, error: error);
    debugPrint('TeamPoolListViewNotifier: load error -> $error');
  }

  void onSearch(String query) => state = state.copyWith(query: query);

  Future<int> usageCount(TeamPool pool) => _service.poolUsageCount(pool.id);

  Future<void> deletePool(TeamPool pool) async {
    try {
      state = state.copyWith(actionError: null);
      await _service.deletePool(pool.id);
    } catch (error) {
      state = state.copyWith(actionError: error);
      debugPrint('TeamPoolListViewNotifier: delete error -> $error');
    }
  }

  @override
  void dispose() {
    _poolSubscription?.cancel();
    _teamSubscription?.cancel();
    super.dispose();
  }
}

class TeamPoolListState {
  final List<TeamPool> pools;
  final List<TournamentTeam> teams;
  final String query;
  final bool loading;
  final Object? error;
  final Object? actionError;
  final String? currentUserId;

  const TeamPoolListState({
    this.pools = const [],
    this.teams = const [],
    this.query = '',
    this.loading = true,
    this.error,
    this.actionError,
    this.currentUserId,
  });

  List<TournamentTeam> teamsIn(String? poolId) =>
      teams.where((team) => team.poolId == poolId).toList();

  /// Teams whose pool no longer exists are treated as ungrouped too.
  List<TournamentTeam> get ungroupedTeams {
    final poolIds = pools.map((pool) => pool.id).toSet();
    return teams
        .where((team) => team.poolId == null || !poolIds.contains(team.poolId))
        .toList();
  }

  List<TeamPool> get filteredPools => filterPools(pools, query);

  TeamPoolListState copyWith({
    List<TeamPool>? pools,
    List<TournamentTeam>? teams,
    String? query,
    bool? loading,
    Object? error = _unset,
    Object? actionError = _unset,
    String? currentUserId,
  }) =>
      TeamPoolListState(
        pools: pools ?? this.pools,
        teams: teams ?? this.teams,
        query: query ?? this.query,
        loading: loading ?? this.loading,
        error: error == _unset ? this.error : error,
        actionError: actionError == _unset ? this.actionError : actionError,
        currentUserId: currentUserId ?? this.currentUserId,
      );
}

const _unset = Object();

List<TeamPool> filterPools(List<TeamPool> pools, String query) {
  final key = query.trim().toLowerCase();
  if (key.isEmpty) return pools;
  return pools
      .where((pool) =>
          pool.name.toLowerCase().contains(key) ||
          (pool.shortName?.toLowerCase().contains(key) ?? false))
      .toList();
}

int playerCountOf(Iterable<TournamentTeam> teams) =>
    teams.fold(0, (sum, team) => sum + team.playerCount);
