import 'dart:async';

import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/service/user/player_link_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/player_phone_field.dart';

final tournamentTeamPlayersStateProvider = StateNotifierProvider.autoDispose
    .family<TournamentTeamPlayersViewNotifier, TournamentTeamPlayersState,
        String>((ref, teamId) {
  return TournamentTeamPlayersViewNotifier(
    ref.read(tournamentTeamServiceProvider),
    ref.read(playerLinkServiceProvider),
    teamId,
    () => ref.read(currentUserPod)?.id,
  );
});

class TournamentTeamPlayersViewNotifier
    extends StateNotifier<TournamentTeamPlayersState> {
  final TournamentTeamService _service;
  final PlayerLinkService _playerLink;
  final String _teamId;
  final String? Function() _currentUserId;
  StreamSubscription? _subscription;

  TournamentTeamPlayersViewNotifier(
    this._service,
    this._playerLink,
    this._teamId,
    this._currentUserId,
  ) : super(const TournamentTeamPlayersState()) {
    load();
  }

  void load() {
    _subscription?.cancel();
    state = state.copyWith(loading: true, error: null);
    _subscription = _service.streamTeam(_teamId).listen(
      (team) async {
        state = state.copyWith(team: team, notFound: team == null);
        if (team != null) await _refreshPlayers();
        state = state.copyWith(loading: false);
      },
      onError: (error) {
        state = state.copyWith(loading: false, error: error);
        debugPrint('TournamentTeamPlayersViewNotifier: load error -> $error');
      },
    );
  }

  Future<void> _refreshPlayers() async {
    final team = state.team;
    if (team == null) return;
    try {
      final players = await _service.getPlayers(team);
      if (mounted) state = state.copyWith(players: players);
    } catch (error) {
      if (mounted) state = state.copyWith(error: error);
    }
  }

  /// Throws on validation / network errors so the form can show them.
  /// A number that already belongs to a player adds that player instead.
  Future<void> savePlayer(
    TournamentTeamPlayer player, [
    PlayerPhoneMatch phone = PlayerPhoneMatch.none,
  ]) async {
    final found = phone.player;
    final organizerId = _currentUserId() ?? '';
    if (player.id.isEmpty) {
      if (found != null) {
        await _service.addExistingPlayer(
          teamId: _teamId,
          userId: found.id,
          name: found.name ?? player.name,
          existing: state.players,
        );
        return;
      }
      await _service.addPlayer(
        player: player,
        existing: state.players,
        createdBy: organizerId,
        e164: phone.e164,
      );
    } else if (found != null && found.id != player.id) {
      await _playerLink.mergeDuplicateInto(
        duplicateId: player.id,
        playerId: found.id,
        organizerId: organizerId,
      );
      await _refreshPlayers();
    } else {
      await _service.updatePlayer(player: player, existing: state.players);
      if (phone.isNew) {
        await _playerLink.linkPlayerPhone(
          playerId: player.id,
          e164: phone.e164!,
          organizerId: organizerId,
        );
      }
      await _refreshPlayers();
    }
  }

  Future<void> removePlayer(TournamentTeamPlayer player) =>
      _runAction(() => _service.removePlayer(state.team!, player.id));

  Future<void> toggleCaptain(TournamentTeamPlayer player) =>
      _runAction(() => _service.setCaptain(
          _teamId, state.team?.captainId == player.id ? null : player.id));

  Future<void> toggleWicketKeeper(TournamentTeamPlayer player) =>
      _runAction(() => _service.setWicketKeeper(
          _teamId, state.team?.wicketKeeperId == player.id ? null : player.id));

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      state = state.copyWith(actionError: null);
      await action();
    } catch (error) {
      state = state.copyWith(actionError: error);
      debugPrint('TournamentTeamPlayersViewNotifier: action error -> $error');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class TournamentTeamPlayersState {
  final TournamentTeam? team;
  final List<TournamentTeamPlayer> players;
  final bool loading;
  final bool notFound;
  final Object? error;
  final Object? actionError;

  const TournamentTeamPlayersState({
    this.team,
    this.players = const [],
    this.loading = true,
    this.notFound = false,
    this.error,
    this.actionError,
  });

  TournamentTeamPlayer? playerById(String? id) =>
      players.where((player) => player.id == id).firstOrNull;

  TournamentTeamPlayersState copyWith({
    TournamentTeam? team,
    List<TournamentTeamPlayer>? players,
    bool? loading,
    bool? notFound,
    Object? error = _unset,
    Object? actionError = _unset,
  }) =>
      TournamentTeamPlayersState(
        team: team ?? this.team,
        players: players ?? this.players,
        loading: loading ?? this.loading,
        notFound: notFound ?? this.notFound,
        error: error == _unset ? this.error : error,
        actionError: actionError == _unset ? this.actionError : actionError,
      );
}

const _unset = Object();
