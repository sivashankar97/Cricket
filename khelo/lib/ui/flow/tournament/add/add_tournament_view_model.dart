import 'package:data/api/match/match_model.dart';
import 'package:data/api/team/team_model.dart';
import 'package:data/api/tournament/tournament_details.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:data/errors/app_error.dart';
import 'package:data/service/file_upload/file_upload_service.dart';
import 'package:data/service/tournament/tournament_service.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:data/utils/constant/firebase_storage_constant.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khelo/domain/extensions/file_extension.dart';
import 'package:khelo/ui/flow/tournament/team_picker/tournament_team_picker_view_model.dart';

part 'add_tournament_view_model.freezed.dart';

final addTournamentStateProvider = StateNotifierProvider.autoDispose<
    AddTournamentViewNotifier, AddTournamentState>((ref) {
  final notifier = AddTournamentViewNotifier(
    ref.read(tournamentServiceProvider),
    ref.read(fileUploadServiceProvider),
    ref.read(tournamentTeamServiceProvider),
    ref.read(currentUserPod)?.id,
  );
  ref.listen(currentUserPod, (previous, next) {
    notifier.setUserId(next?.id);
  });
  return notifier;
});

class AddTournamentViewNotifier extends StateNotifier<AddTournamentState> {
  final FileUploadService _fileUploadService;
  final TournamentService _tournamentService;
  final TournamentTeamService _tournamentTeamService;

  /// Pool the teams were picked from; written to the tournament after saving.
  String? _poolId;
  bool _poolPicked = false;

  final cityController = TextEditingController();
  final groundController = TextEditingController();
  final oversController = TextEditingController();
  BallType? ballType;
  TournamentDetails _initialDetails = const TournamentDetails();

  TournamentDetails get details => TournamentDetails(
        city: cityController.text.trim(),
        ground: groundController.text.trim(),
        ballType: ballType,
        oversPerMatch: int.tryParse(oversController.text.trim()),
      );

  AddTournamentViewNotifier(
    this._tournamentService,
    this._fileUploadService,
    this._tournamentTeamService,
    String? userId,
  ) : super(AddTournamentState(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 1)),
          nameController: TextEditingController(),
          currentUserId: userId,
        ));

  TournamentModel? _editedTournament;

  void setUserId(String? userId) {
    state = state.copyWith(currentUserId: userId);
  }

  void setData(TournamentModel? editedTournament) {
    _editedTournament = editedTournament;
    state.nameController.text = editedTournament?.name ?? '';
    state = state.copyWith(
      bannerImgUrl: editedTournament?.banner_img_url,
      profileImgUrl: editedTournament?.profile_img_url,
      startDate: editedTournament?.start_date ?? DateTime.now(),
      endDate: editedTournament?.end_date ??
          DateTime.now().add(const Duration(days: 1)),
      selectedType: editedTournament?.type ?? TournamentType.knockOut,
      teams: editedTournament?.teams ?? [],
    );
    if (editedTournament != null) _loadDetails(editedTournament.id);
  }

  Future<void> _loadDetails(String tournamentId) async {
    try {
      final details =
          await _tournamentService.getTournamentDetails(tournamentId);
      if (!mounted) return;
      _initialDetails = details;
      cityController.text = details.city ?? '';
      groundController.text = details.ground ?? '';
      oversController.text = details.oversPerMatch?.toString() ?? '';
      ballType = details.ballType;
      onChange();
    } catch (e) {
      debugPrint(
          "AddTournamentViewNotifier: error while loading details -> $e");
    }
  }

  void onBallType(BallType type) {
    ballType = type;
    onChange();
  }

  Future<void> onImageChange({
    required String imagePath,
    bool isBanner = false,
  }) async {
    try {
      state = state.copyWith(
        imageUploading: true,
        actionError: null,
      );
      if (await isFileUnderMaxSize(imagePath)) {
        isBanner
            ? state =
                state.copyWith(bannerPath: imagePath, imageUploading: false)
            : state =
                state.copyWith(profilePath: imagePath, imageUploading: false);
      } else {
        state = state.copyWith(
            imageUploading: false,
            actionError: const LargeAttachmentUploadError());
      }
      onChange();
    } catch (e) {
      state = state.copyWith(imageUploading: false, actionError: e);
      debugPrint("AddTournamentViewNotifier: error while image upload -> $e");
    }
  }

  void onChange() {
    final name = state.nameController.text.trim();

    state = state.copyWith(
      enableButton: name.isNotEmpty &&
          details.isComplete &&
          (_editedTournament != null ||
              state.teams.length >= minTournamentTeams) &&
          (details != _initialDetails ||
              _editedTournament?.name != name ||
              _editedTournament?.type != state.selectedType ||
              _editedTournament?.start_date != state.startDate ||
              _editedTournament?.end_date != state.endDate ||
              _editedTournament?.teams != state.teams ||
              state.profilePath != null ||
              state.bannerPath != null),
    );
  }

  void onSelectType(TournamentType type) {
    state = state.copyWith(selectedType: type);
    onChange();
  }

  void onStartDate(DateTime startDate) {
    DateTime endDate = state.endDate;

    if (startDate.isAfter(endDate)) {
      endDate = startDate.add(Duration(days: 1));
    }
    state = state.copyWith(startDate: startDate, endDate: endDate);
    onChange();
  }

  void onEndDate(DateTime endDate) {
    DateTime startDate = state.startDate;

    if (endDate.isBefore(startDate)) {
      startDate = endDate.subtract(Duration(days: 1));
      if (_editedTournament != null &&
          startDate.isBefore(_editedTournament!.start_date)) {
        startDate = _editedTournament!.start_date;
      }
    }
    state = state.copyWith(endDate: endDate, startDate: startDate);
    onChange();
  }

  void addTournament() async {
    try {
      if (state.currentUserId == null) return;
      state = state.copyWith(loading: true, showDateError: false);

      if (state.endDate.isBefore(state.startDate)) {
        state = state.copyWith(showDateError: true, loading: false);
        return;
      }
      final details = this.details;
      if (!details.isComplete) {
        state = state.copyWith(loading: false);
        return;
      }

      final tournamentId = _tournamentService.generateTournamentId;
      final name = state.nameController.text.trim();

      if (state.profilePath != null) {
        final profileImgUrl = await _fileUploadService.uploadProfileImage(
          filePath: state.profilePath ?? '',
          uploadPath: StorageConst.tournamentProfileUploadPath(
              userId: state.currentUserId!, tournamentId: tournamentId),
        );
        state = state.copyWith(profileImgUrl: profileImgUrl);
      }

      if (state.bannerPath != null) {
        final bannerImgUrl = await _fileUploadService.uploadProfileImage(
          filePath: state.bannerPath ?? '',
          uploadPath: StorageConst.tournamentBannerUploadPath(
              userId: state.currentUserId!, tournamentId: tournamentId),
        );
        state = state.copyWith(bannerImgUrl: bannerImgUrl);
      }

      final tournament = TournamentModel(
        id: _editedTournament?.id ?? tournamentId,
        name: name,
        type: state.selectedType,
        start_date: state.startDate,
        end_date: state.endDate,
        created_at: _editedTournament?.created_at ?? DateTime.now(),
        created_by: _editedTournament?.created_by ?? state.currentUserId!,
        team_ids: state.teams.map((e) => e.id).toList(),
        match_ids: _editedTournament?.match_ids ?? [],
        members: _editedTournament?.members ??
            [
              TournamentMember(
                id: state.currentUserId!,
                role: TournamentMemberRole.organizer,
              ),
            ],
        profile_img_url: state.profileImgUrl,
        banner_img_url: state.bannerImgUrl,
      );

      await _tournamentService.createTournament(tournament);
      await _tournamentService.saveTournamentDetails(tournament.id, details);
      if (_poolPicked) {
        await _tournamentTeamService.setTournamentPool(tournament.id, _poolId);
      }

      state = state.copyWith(
          pop: true, loading: false, error: null, showDateError: false);
    } catch (error) {
      state = state.copyWith(loading: false, error: error);
      debugPrint(
          "AddTournamentViewNotifier: error while adding tournament -> $error");
    }
  }

  void onSelectTeam(List<TeamModel> selectedTeams, {String? poolId}) {
    _poolId = poolId;
    _poolPicked = true;
    state = state.copyWith(teams: selectedTeams);
    onChange();
  }

  void deleteTournament() async {
    try {
      await _tournamentService.deleteTournament(_editedTournament!.id);
    } catch (error) {
      state = state.copyWith(actionError: error);
      debugPrint(
          "AddTournamentViewNotifier: error while deleting tournament -> $error");
    }
  }

  @override
  void dispose() {
    state.nameController.dispose();
    cityController.dispose();
    groundController.dispose();
    oversController.dispose();
    super.dispose();
  }
}

@freezed
class AddTournamentState with _$AddTournamentState {
  const factory AddTournamentState({
    Object? error,
    Object? actionError,
    String? profilePath,
    String? bannerPath,
    String? currentUserId,
    required DateTime endDate,
    required DateTime startDate,
    @Default([]) List<TeamModel> teams,
    @Default(false) bool pop,
    @Default(false) bool loading,
    @Default(false) bool showDateError,
    @Default(false) bool enableButton,
    @Default(false) bool imageUploading,
    @Default(null) String? profileImgUrl,
    @Default(null) String? bannerImgUrl,
    required TextEditingController nameController,
    @Default(TournamentType.knockOut) TournamentType selectedType,
  }) = _AddTournamentState;
}
