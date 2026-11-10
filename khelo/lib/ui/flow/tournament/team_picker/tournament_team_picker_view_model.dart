import 'dart:async';

import 'package:data/api/team/team_model.dart';
import 'package:data/api/tournament_team/squad_clash.dart';
import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:data/extensions/list_extensions.dart';
import 'package:data/service/team/team_service.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:data/storage/provider/preferences_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/ui/flow/team/tournament_teams/pools/team_pool_list_view_model.dart';

const minTournamentTeams = 2;

/// Stored value for "Ungrouped teams" in [lastTeamPoolIdPod].
const _ungroupedPrefValue = '';

final lastTeamPoolIdPod = createPrefProvider<String?>(
  prefKey: 'last_tournament_team_pool_id',
  defaultValue: null,
);

/// What the "Select teams" step pops with.
class TournamentTeamPickerResult {
  final List<TeamModel> teams;

  /// The pool the teams were picked from; null for ungrouped teams.
  final String? poolId;

  const TournamentTeamPickerResult({required this.teams, this.poolId});
}

final tournamentTeamPickerStateProvider = StateNotifierProvider.autoDispose<
    TournamentTeamPickerViewNotifier, TournamentTeamPickerState>((ref) {
  return TournamentTeamPickerViewNotifier(
    ref.read(tournamentTeamServiceProvider),
    ref.read(teamServiceProvider),
    ref.read(currentUserPod)?.id,
    ref.read(lastTeamPoolIdPod.notifier),
  );
});

class TournamentTeamPickerViewNotifier
    extends StateNotifier<TournamentTeamPickerState> {
  final TournamentTeamService _service;
  final TeamService _teamService;
  final String? _userId;
  final PreferenceNotifier<String?> _lastPoolPref;
  StreamSubscription? _teamSubscription;
  StreamSubscription? _poolSubscription;
  List<TeamModel> _initialTeams = const [];
  bool _teamsLoaded = false;
  bool _poolsLoaded = false;
  bool _poolResolved = false;

  TournamentTeamPickerViewNotifier(
    this._service,
    this._teamService,
    this._userId,
    this._lastPoolPref,
  ) : super(const TournamentTeamPickerState());

  void setData(List<TeamModel> selectedTeams) {
    _initialTeams = selectedTeams;
    state = state.copyWith(
      selectedIds: selectedTeams.map((team) => team.id).toSet(),
    );
    load();
  }

  void load() {
    _teamSubscription?.cancel();
    _poolSubscription?.cancel();
    if (_userId == null) {
      state = state.copyWith(loading: false);
      return;
    }
    _teamsLoaded = false;
    _poolsLoaded = false;
    state = state.copyWith(loading: true, error: null);
    _teamSubscription = _service.streamTeams(_userId).listen(
      (teams) {
        _teamsLoaded = true;
        final teamIds = teams.map((team) => team.id).toSet();
        final extras = _initialTeams
            .where((team) => !teamIds.contains(team.id))
            .map(TournamentTeam.fromTeamModel)
            .toList();
        state = state.copyWith(allTeams: teams, extraTeams: extras);
        _onLoaded();
      },
      onError: _onError,
    );
    _poolSubscription = _service.streamPools(_userId).listen(
      (pools) {
        _poolsLoaded = true;
        state = state.copyWith(pools: pools);
        _onLoaded();
      },
      onError: _onError,
    );
  }

  void _onError(Object error) {
    state = state.copyWith(loading: false, error: error);
    debugPrint('TournamentTeamPickerViewNotifier: load error -> $error');
  }

  void _onLoaded() {
    if (!_teamsLoaded || !_poolsLoaded) return;
    state = state.copyWith(loading: false, error: null);
    if (_poolResolved) return;
    _poolResolved = true;
    _resolveInitialPool();
  }

  /// Opens the pool of an already selected team, else the last pool used,
  /// else the only pool.
  void _resolveInitialPool() {
    final poolIds = state.pools.map((pool) => pool.id).toSet();
    final selectedPoolTeam = state.allTeams
        .where((team) => state.selectedIds.contains(team.id))
        .firstOrNull;
    if (selectedPoolTeam != null) {
      final poolId = selectedPoolTeam.poolId;
      _choose(poolIds.contains(poolId) ? poolId : null);
      return;
    }
    final last = _lastPoolPref.state;
    if (last != null && poolIds.contains(last)) {
      _choose(last);
    } else if (last == _ungroupedPrefValue && state.ungroupedTeams.isNotEmpty) {
      _choose(null);
    } else if (state.pools.length == 1) {
      _choose(state.pools.first.id);
    } else if (state.pools.isEmpty && state.ungroupedTeams.isNotEmpty) {
      _choose(null);
    }
  }

  void _choose(String? poolId) => state = state.copyWith(
        selectedPoolId: poolId,
        ungroupedSelected: poolId == null,
        poolChosen: true,
      );

  /// Pass a null [poolId] for "Ungrouped teams".
  void selectPool(String? poolId, {bool clearSelection = false}) {
    _choose(poolId);
    if (clearSelection) clear();
  }

  void onSearch(String query) => state = state.copyWith(query: query);

  void toggle(String teamId) {
    final ids = {...state.selectedIds};
    ids.contains(teamId) ? ids.remove(teamId) : ids.add(teamId);
    state = state.copyWith(selectedIds: ids);
  }

  void select(String teamId) =>
      state = state.copyWith(selectedIds: {...state.selectedIds, teamId});

  void selectAll() => state = state.copyWith(selectedIds: {
        ...state.selectedIds,
        ...state.filteredTeams.map((team) => team.id),
      });

  void clear() => state = state.copyWith(selectedIds: {});

  /// Loads the selected teams with their players for the tournament.
  Future<TournamentTeamPickerResult?> confirm() async {
    try {
      state = state.copyWith(saving: true, actionError: null);
      final ids = state.selectedIds.toList();
      final teams = <TeamModel>[];
      for (final chunk in ids.chunked(10)) {
        teams.addAll(await _teamService.getTeamsByIds(chunk));
      }
      _ensureOneTeamPerPlayer(teams);
      final poolId = state.ungroupedSelected ? null : state.selectedPoolId;
      if (state.poolChosen) {
        _lastPoolPref.state = poolId ?? _ungroupedPrefValue;
      }
      state = state.copyWith(saving: false);
      return TournamentTeamPickerResult(teams: teams, poolId: poolId);
    } catch (error) {
      state = state.copyWith(saving: false, actionError: error);
      debugPrint('TournamentTeamPickerViewNotifier: confirm error -> $error');
      return null;
    }
  }

  void _ensureOneTeamPerPlayer(List<TeamModel> teams) {
    final clash = findSquadClash(teams.map((team) => (
          id: team.id,
          name: team.name,
          playerIds: team.players.map((p) => p.id),
        )));
    if (clash == null) return;
    final player = teams
        .expand((team) => team.players)
        .firstWhere((p) => p.id == clash.playerId)
        .user;
    throw PlayerTeamClashError(
      playerName: player.name ?? '',
      teamName: clash.team.name,
      otherTeamName: clash.other.name,
    );
  }

  @override
  void dispose() {
    _teamSubscription?.cancel();
    _poolSubscription?.cancel();
    super.dispose();
  }
}

class TournamentTeamPickerState {
  final List<TeamPool> pools;
  final List<TournamentTeam> allTeams;
  final List<TournamentTeam> extraTeams;
  final String? selectedPoolId;
  final bool ungroupedSelected;
  final bool poolChosen;
  final Set<String> selectedIds;
  final String query;
  final bool loading;
  final bool saving;
  final Object? error;
  final Object? actionError;

  const TournamentTeamPickerState({
    this.pools = const [],
    this.allTeams = const [],
    this.extraTeams = const [],
    this.selectedPoolId,
    this.ungroupedSelected = false,
    this.poolChosen = false,
    this.selectedIds = const {},
    this.query = '',
    this.loading = true,
    this.saving = false,
    this.error,
    this.actionError,
  });

  List<TournamentTeam> get ungroupedTeams {
    final poolIds = pools.map((pool) => pool.id).toSet();
    return allTeams
        .where((team) => team.poolId == null || !poolIds.contains(team.poolId))
        .toList();
  }

  TeamPool? get selectedPool => ungroupedSelected
      ? null
      : pools.where((pool) => pool.id == selectedPoolId).firstOrNull;

  /// Teams of the chosen pool.
  List<TournamentTeam> get poolTeams {
    if (!poolChosen) return const [];
    if (ungroupedSelected) return ungroupedTeams;
    return allTeams.where((team) => team.poolId == selectedPoolId).toList();
  }

  bool get hasAnything =>
      pools.isNotEmpty || allTeams.isNotEmpty || extraTeams.isNotEmpty;

  /// The search box looks up pools, not teams.
  bool get searching => query.trim().isNotEmpty;

  List<TeamPool> get filteredPools => filterPools(pools, query);

  List<TournamentTeam> teamsInPool(String poolId) =>
      allTeams.where((team) => team.poolId == poolId).toList();

  List<TournamentTeam> get filteredTeams => [...extraTeams, ...poolTeams];

  bool get canContinue => selectedIds.length >= minTournamentTeams;

  TournamentTeamPickerState copyWith({
    List<TeamPool>? pools,
    List<TournamentTeam>? allTeams,
    List<TournamentTeam>? extraTeams,
    String? selectedPoolId,
    bool? ungroupedSelected,
    bool? poolChosen,
    Set<String>? selectedIds,
    String? query,
    bool? loading,
    bool? saving,
    Object? error = _unset,
    Object? actionError = _unset,
  }) =>
      TournamentTeamPickerState(
        pools: pools ?? this.pools,
        allTeams: allTeams ?? this.allTeams,
        extraTeams: extraTeams ?? this.extraTeams,
        selectedPoolId: selectedPoolId ?? this.selectedPoolId,
        ungroupedSelected: ungroupedSelected ?? this.ungroupedSelected,
        poolChosen: poolChosen ?? this.poolChosen,
        selectedIds: selectedIds ?? this.selectedIds,
        query: query ?? this.query,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        error: error == _unset ? this.error : error,
        actionError: actionError == _unset ? this.actionError : actionError,
      );
}

const _unset = Object();
