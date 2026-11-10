import 'dart:async';

import 'package:data/api/team/team_model.dart';
import 'package:data/api/user/user_models.dart';
import 'package:data/service/team/team_service.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/service/user/player_link_service.dart';
import 'package:data/service/user/user_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khelo/domain/phone/phone_number.dart';

part 'add_team_member_view_model.freezed.dart';

final addTeamMemberStateProvider = StateNotifierProvider.autoDispose<
    AddTeamMemberViewNotifier, AddTeamMemberState>((ref) {
  return AddTeamMemberViewNotifier(
    ref.read(userServiceProvider),
    ref.read(teamServiceProvider),
    ref.read(tournamentTeamServiceProvider),
    ref.read(playerLinkServiceProvider),
    ref.read(currentUserPod)?.id,
  );
});

/// Thrown when a typed mobile number can't be read.
class InvalidPhoneError implements Exception {
  const InvalidPhoneError();
}

class AddTeamMemberViewNotifier extends StateNotifier<AddTeamMemberState> {
  final UserService _userService;
  final TeamService _teamService;
  final TournamentTeamService _tournamentTeamService;
  final PlayerLinkService _playerLink;
  final String? _currentUserId;
  Timer? _debounce;
  TeamModel? _team;

  /// Country assumed for numbers typed without a `+` code.
  PhoneCountry defaultCountry = PhoneCountry.india;

  AddTeamMemberViewNotifier(
    this._userService,
    this._teamService,
    this._tournamentTeamService,
    this._playerLink,
    this._currentUserId,
  ) : super(AddTeamMemberState(searchController: TextEditingController()));

  void setData(TeamModel team) {
    _team = team;
  }

  Future<void> _search(String searchKey) async {
    try {
      if (searchKey.isEmpty) {
        state = state.copyWith(searchedUsers: []);
        return;
      }
      if (looksLikePhone(searchKey)) {
        final e164 = toE164(searchKey);
        final user =
            e164 == null ? null : await _playerLink.findPlayerByPhone(e164);
        if (!mounted || state.searchController.text.trim() != searchKey) {
          return;
        }
        state = state.copyWith(
          searchedUsers: user == null ? [] : [user],
          error: null,
        );
        return;
      }
      final users = await _userService.searchUser(searchKey);
      state = state.copyWith(searchedUsers: users, error: null);
    } catch (e) {
      state = state.copyWith(error: e);
      debugPrint("AddTeamMemberViewNotifier: error while search players -> $e");
    }
  }

  void onSearchChanged() {
    if (_debounce != null && _debounce!.isActive) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      _search(state.searchController.text.trim());
    });
  }

  void selectUser(UserModel user) {
    final role = (_team?.created_by == user.id)
        ? TeamPlayerRole.admin
        : TeamPlayerRole.player;
    final player = TeamPlayer(id: user.id, role: role, user: user);
    state = state.copyWith(selectedUsers: [...state.selectedUsers, player]);
  }

  static bool looksLikePhone(String input) =>
      RegExp(r'^\+?[\d\s\-()]{7,}$').hasMatch(input.trim());

  /// Full number with country code, or null when it isn't a valid mobile.
  String? toE164(String input) => PhoneNumber.toE164(input, defaultCountry);

  /// Creates the player, or picks the existing one with the same number
  /// (`existing: true`).
  Future<({UserModel user, bool existing})> createPlayer({
    required String name,
    String? phone,
  }) async {
    if (phone == null || phone.trim().isEmpty) {
      final user = await _userService.createPlayer(name: name);
      selectUser(user);
      return (user: user, existing: false);
    }
    final e164 = toE164(phone);
    if (e164 == null) throw const InvalidPhoneError();
    final result = await _playerLink.createPlayerWithPhone(
      name: name,
      e164: e164,
      organizerId: _currentUserId ?? '',
    );
    if (!getMemberIds().contains(result.user.id)) selectUser(result.user);
    return result;
  }

  void unSelectUser(UserModel user) {
    final updatedList = state.selectedUsers.toList();
    updatedList.removeWhere((element) => element.id == user.id);
    state = state.copyWith(selectedUsers: updatedList);
  }

  Future<void> addPlayersToTeam() async {
    state = state.copyWith(isAddInProgress: true, actionError: null);
    try {
      final teamId = _team?.id ?? '';
      final current = _team?.players.map((p) => p.id).toSet() ?? {};
      await _tournamentTeamService.ensureOneTeamPerTournament(
        teamId: teamId,
        players: {
          for (final p in state.selectedUsers)
            if (!current.contains(p.id)) p.id: p.user.name ?? '',
        },
      );
      await _teamService.addPlayersToTeam(teamId, state.selectedUsers);
      state = state.copyWith(isAddInProgress: false, isAdded: true);
    } catch (e) {
      state = state.copyWith(isAddInProgress: false, actionError: e);
      debugPrint(
          "AddTeamMemberViewNotifier: error while adding players to team -> $e");
    }
  }

  List<String> getMemberIds() {
    var memberIds = _team?.players.map((e) => e.id).toList() ?? [];
    memberIds.addAll(state.selectedUsers.map((e) => e.id));
    return memberIds;
  }

  @override
  void dispose() {
    state.searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

@freezed
class AddTeamMemberState with _$AddTeamMemberState {
  const factory AddTeamMemberState({
    required TextEditingController searchController,
    Object? error,
    Object? actionError,
    @Default([]) List<UserModel> searchedUsers,
    @Default([]) List<TeamPlayer> selectedUsers,
    @Default(false) bool isAdded,
    @Default(false) bool isAddInProgress,
  }) = _AddTeamMemberState;
}
