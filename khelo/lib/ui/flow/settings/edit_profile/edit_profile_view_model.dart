import 'dart:async';

import 'package:data/api/user/user_models.dart';
import 'package:data/errors/app_error.dart';
import 'package:data/service/auth/auth_service.dart';
import 'package:data/service/file_upload/file_upload_service.dart';
import 'package:data/service/file_upload/local_file_upload.dart';
import 'package:data/service/match/match_service.dart';
import 'package:data/service/team/team_service.dart';
import 'package:data/service/tournament/tournament_service.dart';
import 'package:data/service/user/player_link_service.dart';
import 'package:data/service/user/user_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:data/storage/provider/preferences_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:khelo/domain/image/profile_photo.dart';
import 'package:khelo/domain/phone/phone_number.dart';
import 'package:khelo/ui/flow/settings/edit_profile/profile_completion.dart';

final editProfileStateProvider = StateNotifierProvider.autoDispose<
    EditProfileViewNotifier, EditProfileState>((ref) {
  final notifier = EditProfileViewNotifier(
    ref.read(fileUploadServiceProvider),
    ref.read(userServiceProvider),
    ref.read(authServiceProvider),
    ref.read(teamServiceProvider),
    ref.read(matchServiceProvider),
    ref.read(tournamentServiceProvider),
    ref.read(currentUserPod),
    ref.read(currentUserJsonPod.notifier),
    playerLink: ref.read(playerLinkServiceProvider),
  );
  ref.listen(currentUserPod, (_, next) => notifier._updateUser(next));
  return notifier;
});

/// Fields Create Profile checks before saving.
enum ProfileField { name, phone, email }

class EditProfileViewNotifier extends StateNotifier<EditProfileState> {
  final FileUploadService _fileUploadService;
  final UserService userService;
  final AuthService _authService;
  final TeamService _teamService;
  final MatchService _matchService;
  final TournamentService _tournamentService;
  final PreferenceNotifier<String?> _userJsonController;
  final PlayerLinkService? _playerLink;

  /// Number saved before this edit, to free its lookup entry when changed.
  String? _savedPhone;

  EditProfileViewNotifier(
    this._fileUploadService,
    this.userService,
    this._authService,
    this._teamService,
    this._matchService,
    this._tournamentService,
    UserModel? user,
    this._userJsonController, {
    PlayerLinkService? playerLink,
  })  : _playerLink = playerLink,
        super(EditProfileState(
          dob: user?.dob,
          imageUrl: user?.profile_img_url,
          battingStyle: user?.batting_style,
          bowlingStyle: user?.bowling_style,
          gender: user?.gender,
          playerRole: user?.player_role,
          phoneCountry:
              PhoneNumber.parse(user?.phone)?.country ?? PhoneCountry.india,
          nameController: TextEditingController(text: user?.name),
          emailController: TextEditingController(text: user?.email),
          phoneController: TextEditingController(
              text: PhoneNumber.parse(user?.phone)?.digits),
          currentUser: user,
          locationController: TextEditingController(text: user?.location),
        )) {
    _loadPrivatePhone();
  }

  Future<void> _loadPrivatePhone() async {
    final userId = state.currentUser?.id;
    if (userId == null) return;
    try {
      final stored = await userService.streamPrivatePhone(userId).first;
      _savedPhone = stored;
      final phone = PhoneNumber.parse(stored);
      if (!mounted || phone == null) return;
      if (state.phoneController.text.trim().isEmpty ||
          state.phoneController.text.trim() == phone.digits) {
        state.phoneController.text = phone.digits;
        state = state.copyWith(phoneCountry: phone.country);
        _revalidate();
      }
    } catch (e) {
      debugPrint("EditProfileViewNotifier: error while loading phone -> $e");
    }
  }

  void _updateUser(UserModel? user) {
    state = state.copyWith(currentUser: user);
  }

  void onDateSelect({required DateTime selectedDate}) {
    state = state.copyWith(dob: selectedDate);
  }

  void onGenderSelect({required UserGender gender}) {
    state = state.copyWith(gender: gender);
  }

  void onBattingStyleChange(BattingStyle style) {
    state = state.copyWith(battingStyle: style);
  }

  void onBowlingStyleChange(BowlingStyle style) {
    state = state.copyWith(bowlingStyle: style);
  }

  void onPlayerRoleChange(PlayerRole role) {
    state = state.copyWith(playerRole: role);
  }

  void onPhoneCountryChange(PhoneCountry country) {
    state = state.copyWith(phoneCountry: country);
    _revalidate();
  }

  /// Re-checks fields after the first submit so errors clear as you type.
  void onValueChange() => _revalidate();

  void _revalidate() {
    if (!state.submitted) return;
    state = state.copyWith(errors: validate());
  }

  /// Missing or wrong fields, in screen order.
  List<ProfileField> validate() {
    final name = state.nameController.text.trim();
    final email = state.emailController.text.trim();
    return [
      if (name.length < ProfileRules.minNameLength) ProfileField.name,
      if (PhoneNumber.validate(
              state.phoneCountry, state.phoneController.text) !=
          null)
        ProfileField.phone,
      if (email.isNotEmpty && !email.isValidEmail()) ProfileField.email,
    ];
  }

  PhoneError? get phoneError =>
      PhoneNumber.validate(state.phoneCountry, state.phoneController.text);

  /// Shrinks the picked photo to a small square JPEG kept with the profile.
  /// Returns false when the file isn't a usable image.
  Future<bool> onImageChange(String imagePath) async {
    state = state.copyWith(isImageUploading: true, actionError: null);
    try {
      final bytes = await readLocalFileBytes(imagePath);
      final photo = await ProfilePhoto.encode(bytes);
      if (!mounted) return false;
      state = state.copyWith(
        isImageUploading: false,
        newImage: photo ?? state.newImage,
        imageRemoved: photo == null && state.imageRemoved,
      );
      return photo != null;
    } catch (e) {
      debugPrint("EditProfileViewNotifier: error while reading photo -> $e");
      if (mounted) state = state.copyWith(isImageUploading: false);
      return false;
    }
  }

  void onRemoveImage() {
    state = state.copyWith(newImage: null, imageRemoved: true);
  }

  /// Lets organizers find this player by number. A failure here must not
  /// block saving the profile.
  Future<void> _registerPhone(String userId, String e164) async {
    try {
      await _playerLink?.registerOwnPhone(
        userId: userId,
        e164: e164,
        previousE164: _savedPhone ?? state.currentUser?.phone,
      );
      _savedPhone = e164;
    } catch (e) {
      debugPrint("EditProfileViewNotifier: error while linking phone -> $e");
    }
  }

  /// Saves the profile, or returns the fields that still need fixing.
  Future<List<ProfileField>> onSubmitTap() async {
    final user = state.currentUser;
    if (user == null || state.isSaveInProgress) return const [];
    final errors = validate();
    state = state.copyWith(submitted: true, errors: errors, actionError: null);
    if (errors.isNotEmpty) return errors;

    state = state.copyWith(isSaveInProgress: true);
    try {
      final name = state.nameController.text.trim();
      final email = state.emailController.text.trim();
      final location = state.locationController.text.trim();
      final phone = PhoneNumber(
        state.phoneCountry,
        PhoneNumber.clean(state.phoneCountry, state.phoneController.text),
      );
      final oldImage = user.profile_img_url;
      final image = state.photoUrl;

      final updated = user.copyWith(
        name: name,
        name_lowercase: name.toLowerCase(),
        email: email.isEmpty ? user.email : email,
        location: location.isEmpty ? null : location.toLowerCase(),
        batting_style: state.battingStyle,
        bowling_style: state.bowlingStyle,
        player_role: state.playerRole,
        gender: state.gender,
        profile_img_url: image,
        dob: state.dob,
        phone: null,
        created_at: user.created_at ?? DateTime.now(),
        updated_at: DateTime.now(),
      );

      await userService.savePrivatePhone(user.id, phone.e164);
      await userService.updateUser(updated);
      await _registerPhone(user.id, phone.e164);
      _userJsonController.state = updated.toJsonString();
      if (oldImage != null && oldImage != image) {
        unawaited(_deleteUnusedImage(oldImage));
      }
      state = state.copyWith(isSaveInProgress: false, isSaved: true);
    } catch (e) {
      state = state.copyWith(isSaveInProgress: false, actionError: e);
      debugPrint(
          "EditProfileViewNotifier: error while edit profile details -> $e");
    }
    return const [];
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      state = state.copyWith(actionError: e);
    }
  }

  Future<void> onDeleteTap() async {
    try {
      state = state.copyWith(actionError: null);
      final userProfileImageUrl = state.currentUser!.profile_img_url;
      await _authService.deleteAccount();

      if (userProfileImageUrl != null) {
        await _deleteUnusedImage(userProfileImageUrl);
      }
    } catch (e) {
      if (e is RequiresRecentLoginError) {
        await _reAuthenticateAndDelete();
      }
      state = state.copyWith(actionError: e);

      debugPrint("EditProfileViewNotifier: error while delete account -> $e");
    }
  }

  Future<void> checkUserOwnershipAndShowDialog() async {
    try {
      final userId = state.currentUser?.id;
      if (userId == null) return;
      state = state.copyWith(
        showDeleteConfirmationDialog: false,
        showTransferTeamsSheet: false,
      );

      final [matchCount, teamCount, tournamentCount] = await Future.wait([
        _matchService.getUserOwnedMatchesCount(userId),
        _teamService.getUserOwnedTeamsCount(userId),
        _tournamentService.getUserOwnedTournamentsCount(userId)
      ]);
      if (teamCount == 0 && matchCount == 0 && tournamentCount == 0) {
        state = state.copyWith(showDeleteConfirmationDialog: true);
      } else {
        state = state.copyWith(showTransferTeamsSheet: true);
      }
    } catch (e) {
      state = state.copyWith(actionError: e);
      debugPrint(
          "EditProfileViewNotifier: error while fetching user teams -> $e");
    }
  }

  Future<void> _reAuthenticateAndDelete() async {
    try {
      final userProfileImageUrl = state.currentUser!.profile_img_url;
      _authService.reAuthenticateAndDeleteAccount();
      if (userProfileImageUrl != null) {
        await _deleteUnusedImage(userProfileImageUrl);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "web-user-interaction-failure") {
        // TODO: handle the error when user account has been deleted after creating in few course of time
        debugPrint(
            "EditProfileViewNotifier: error in _reAuthenticateAndDelete -> $e");
      }
    } catch (e) {
      debugPrint(
          "EditProfileViewNotifier: error in reAuthenticate And Delete -> $e");
    }
  }

  /// Old uploaded files only; inline photos go away with the profile.
  Future<void> _deleteUnusedImage(String imgUrl) async {
    if (ProfilePhoto.isInline(imgUrl)) return;
    try {
      await _fileUploadService.deleteUploadedImage(imgUrl);
    } catch (e) {
      debugPrint(
          "EditProfileViewNotifier: error while deleting Unused Image -> $e");
    }
  }

  @override
  void dispose() {
    state.nameController.dispose();
    state.emailController.dispose();
    state.phoneController.dispose();
    state.locationController.dispose();
    super.dispose();
  }
}

/// Sentinel so [EditProfileState.copyWith] can tell "not passed" from null.
const _keep = Object();

class EditProfileState {
  final DateTime? dob;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final PhoneCountry phoneCountry;
  final Object? actionError;
  final UserModel? currentUser;

  /// Freshly picked photo (inline JPEG), not saved yet.
  final String? newImage;
  final bool imageRemoved;
  final String? imageUrl;
  final UserGender? gender;
  final BattingStyle? battingStyle;
  final BowlingStyle? bowlingStyle;
  final PlayerRole? playerRole;
  final bool submitted;
  final List<ProfileField> errors;
  final bool isImageUploading;
  final bool isSaved;
  final bool isSaveInProgress;
  final bool showDeleteConfirmationDialog;
  final bool showTransferTeamsSheet;

  const EditProfileState({
    this.dob,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.locationController,
    required this.phoneCountry,
    this.actionError,
    this.currentUser,
    this.newImage,
    this.imageRemoved = false,
    this.imageUrl,
    this.gender,
    this.battingStyle,
    this.bowlingStyle,
    this.playerRole,
    this.submitted = false,
    this.errors = const [],
    this.isImageUploading = false,
    this.isSaved = false,
    this.isSaveInProgress = false,
    this.showDeleteConfirmationDialog = false,
    this.showTransferTeamsSheet = false,
  });

  /// Photo the profile will have after saving.
  String? get photoUrl => newImage ?? (imageRemoved ? null : imageUrl);

  EditProfileState copyWith({
    Object? dob = _keep,
    PhoneCountry? phoneCountry,
    Object? actionError = _keep,
    Object? currentUser = _keep,
    Object? newImage = _keep,
    bool? imageRemoved,
    Object? gender = _keep,
    Object? battingStyle = _keep,
    Object? bowlingStyle = _keep,
    Object? playerRole = _keep,
    bool? submitted,
    List<ProfileField>? errors,
    bool? isImageUploading,
    bool? isSaved,
    bool? isSaveInProgress,
    bool? showDeleteConfirmationDialog,
    bool? showTransferTeamsSheet,
  }) =>
      EditProfileState(
        dob: dob == _keep ? this.dob : dob as DateTime?,
        nameController: nameController,
        emailController: emailController,
        phoneController: phoneController,
        locationController: locationController,
        phoneCountry: phoneCountry ?? this.phoneCountry,
        actionError: actionError == _keep ? this.actionError : actionError,
        currentUser:
            currentUser == _keep ? this.currentUser : currentUser as UserModel?,
        newImage: newImage == _keep ? this.newImage : newImage as String?,
        imageRemoved: imageRemoved ?? this.imageRemoved,
        imageUrl: imageUrl,
        gender: gender == _keep ? this.gender : gender as UserGender?,
        battingStyle: battingStyle == _keep
            ? this.battingStyle
            : battingStyle as BattingStyle?,
        bowlingStyle: bowlingStyle == _keep
            ? this.bowlingStyle
            : bowlingStyle as BowlingStyle?,
        playerRole:
            playerRole == _keep ? this.playerRole : playerRole as PlayerRole?,
        submitted: submitted ?? this.submitted,
        errors: errors ?? this.errors,
        isImageUploading: isImageUploading ?? this.isImageUploading,
        isSaved: isSaved ?? this.isSaved,
        isSaveInProgress: isSaveInProgress ?? this.isSaveInProgress,
        showDeleteConfirmationDialog:
            showDeleteConfirmationDialog ?? this.showDeleteConfirmationDialog,
        showTransferTeamsSheet:
            showTransferTeamsSheet ?? this.showTransferTeamsSheet,
      );
}
