import 'package:data/api/user/user_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/action_bottom_sheet.dart';
import 'package:khelo/components/app_image_provider.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/confirmation_dialog.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/image_picker_sheet.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/components/mascot/mascot_reactions.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:khelo/domain/phone/phone_number.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/settings/edit_profile/component/transfer_teams_sheet.dart';
import 'package:khelo/ui/flow/settings/edit_profile/edit_profile_view_model.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/pickers/date_and_time_picker.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

/// Create Profile (after sign-in, when name or mobile is missing) and Edit
/// Profile. Name and mobile are required; the tiger points out what's missing.
class EditProfileScreen extends ConsumerStatefulWidget {
  final bool isToCreateAccount;

  const EditProfileScreen({super.key, required this.isToCreateAccount});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const _maxWidth = 560.0;

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool get _creating => widget.isToCreateAccount;

  @override
  void initState() {
    super.initState();
    if (_creating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(mascotProvider.notifier).show(
              MascotPose.help,
              mascotText.mascot_profile_required,
              delay: const Duration(milliseconds: 600),
              allowFun: false,
            );
      });
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(editProfileStateProvider.notifier);
    final state = ref.watch(editProfileStateProvider);

    _observeActionError();
    _observeIsSaved();
    _observeShowDeleteConfirmationDialog(notifier.onDeleteTap);
    _observeShowTransferTeamsSheet();

    return AppPage(
      title: _creating ? '' : context.l10n.edit_profile_screen_title,
      automaticallyImplyLeading: !_creating,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: context.mediaQueryPadding +
                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  _centered(_hero(state, notifier)),
                  const SizedBox(height: 16),
                  _centered(_basicSection(state, notifier)),
                  const SizedBox(height: 16),
                  _centered(_personalSection(state, notifier)),
                  const SizedBox(height: 16),
                  _centered(_cricketSection(state, notifier)),
                  const SizedBox(height: 16),
                  if (_creating)
                    _centered(_signOutLink(notifier))
                  else
                    _centered(_deleteAccount(notifier)),
                ],
              ),
            ),
          ),
          _bottomBar(state, notifier),
        ],
      ),
    );
  }

  Widget _centered(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: child,
        ),
      );

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _hero(EditProfileState state, EditProfileViewNotifier notifier) {
    final done = _completedCount(state);
    const total = 9;
    final photo = state.photoUrl;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandNavyCardColor, brandNavyColor],
        ),
        boxShadow: context.colorScheme.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandRedColor.withValues(alpha: 0.9),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                _avatar(state, notifier, photo),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _heroLink(
                      photo == null
                          ? context.l10n.profile_form_photo_add
                          : context.l10n.profile_form_photo_change,
                      onTap: () => _pickPhoto(notifier),
                    ),
                    if (photo != null) ...[
                      Text(' · ',
                          style: AppTextStyle.caption
                              .copyWith(color: textSecondaryDarkColor)),
                      _heroLink(
                        context.l10n.profile_form_photo_remove,
                        onTap: notifier.onRemoveImage,
                      ),
                    ] else
                      Text(
                        '  (${context.l10n.profile_form_photo_optional})',
                        style: AppTextStyle.caption
                            .copyWith(color: textSecondaryDarkColor),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _creating
                      ? context.l10n.profile_form_create_heading
                      : context.l10n.profile_form_edit_heading,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.header3.copyWith(
                    color: textPrimaryDarkColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _creating
                      ? context.l10n.profile_form_create_subtitle
                      : context.l10n.profile_form_edit_subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.body2
                      .copyWith(color: textSecondaryDarkColor),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: done / total),
                          duration: const Duration(milliseconds: 400),
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            valueColor:
                                const AlwaysStoppedAnimation(brandRedColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.profile_form_progress(done, total),
                      style: AppTextStyle.caption.copyWith(
                        color: textPrimaryDarkColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _completedCount(EditProfileState state) {
    final phoneOk =
        PhoneNumber.validate(state.phoneCountry, state.phoneController.text) ==
            null;
    return [
      state.nameController.text.trim().length >= 2,
      phoneOk,
      state.photoUrl != null,
      state.locationController.text.trim().isNotEmpty,
      state.dob != null,
      state.gender != null && state.gender != UserGender.unknown,
      state.playerRole != null,
      state.battingStyle != null,
      state.bowlingStyle != null,
    ].where((done) => done).length;
  }

  Widget _avatar(
    EditProfileState state,
    EditProfileViewNotifier notifier,
    String? photo,
  ) {
    final name = state.nameController.text.trim();
    return OnTapScale(
      onTap: () => _pickPhoto(notifier),
      child: SizedBox(
        width: 108,
        height: 108,
        child: Stack(
          children: [
            Container(
              width: 108,
              height: 108,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: textPrimaryDarkColor,
              ),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brandNavyCardColor,
                  image: photo == null
                      ? null
                      : DecorationImage(
                          image: appImageProvider(photo),
                          fit: BoxFit.cover,
                        ),
                ),
                child: state.isImageUploading
                    ? const AppProgressIndicator(color: textPrimaryDarkColor)
                    : photo != null
                        ? null
                        : name.isEmpty
                            ? const Icon(CupertinoIcons.person_fill,
                                size: 46, color: textSecondaryDarkColor)
                            : Text(
                                name.characters.first.toUpperCase(),
                                style: AppTextStyle.header1.copyWith(
                                  color: textPrimaryDarkColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: brandRedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: textPrimaryDarkColor, width: 2.5),
                ),
                child: const Icon(CupertinoIcons.camera_fill,
                    size: 16, color: textPrimaryDarkColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroLink(String text, {required VoidCallback onTap}) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Text(
        text,
        style: AppTextStyle.subtitle3.copyWith(
          color: textPrimaryDarkColor,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: textSecondaryDarkColor,
        ),
      ),
    );
  }

  Future<void> _pickPhoto(EditProfileViewNotifier notifier) async {
    final path = await ImagePickerSheet.show<String>(
      context,
      allowCrop: true,
      maxDimension: 1024,
    );
    if (path == null || !mounted) return;
    final ok = await notifier.onImageChange(path);
    if (!mounted) return;
    final mascot = ref.read(mascotProvider.notifier);
    if (ok) {
      mascot.show(MascotPose.celebrate, mascotText.mascot_profile_photo_added,
          duration: const Duration(seconds: 3));
    } else {
      showSnackBar(context, context.l10n.profile_form_error_photo);
      mascot.show(MascotPose.error, mascotText.mascot_profile_photo_failed,
          allowFun: false);
    }
  }

  // ── Sections ─────────────────────────────────────────────────────────────

  Widget _section({
    required IconData icon,
    required String title,
    required String tag,
    bool required = false,
    required List<Widget> children,
  }) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: cs.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: brandRedColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: brandRedColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(icon, size: 16, color: textPrimaryDarkColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyle.header4.copyWith(
                    color: cs.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: required ? cs.primaryVariant : cs.containerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: AppTextStyle.caption.copyWith(
                    color: required ? cs.primary : cs.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _basicSection(
    EditProfileState state,
    EditProfileViewNotifier notifier,
  ) {
    final errors = state.errors;
    final phoneError = errors.contains(ProfileField.phone)
        ? notifier.phoneError == PhoneError.empty
            ? context.l10n.profile_form_error_phone_empty
            : context.l10n
                .profile_form_error_phone_invalid(state.phoneCountry.name)
        : null;
    return _section(
      icon: CupertinoIcons.person_fill,
      title: context.l10n.profile_form_section_basic,
      tag: context.l10n.profile_form_required,
      required: true,
      children: [
        _label(context.l10n.profile_form_name_label, required: true),
        _textField(
          controller: state.nameController,
          focusNode: _nameFocus,
          hint: context.l10n.profile_form_name_hint,
          icon: CupertinoIcons.person,
          error: errors.contains(ProfileField.name)
              ? context.l10n.profile_form_error_name
              : null,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            notifier.onValueChange();
            setState(() {});
            _greetName(value);
          },
        ),
        const SizedBox(height: 14),
        _label(context.l10n.profile_form_phone_label, required: true),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _countryButton(state, notifier),
            const SizedBox(width: 8),
            Expanded(
              child: _textField(
                controller: state.phoneController,
                focusNode: _phoneFocus,
                hint: _phoneHint(state.phoneCountry),
                icon: CupertinoIcons.phone,
                error: phoneError,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-+]')),
                  LengthLimitingTextInputFormatter(18),
                ],
                onChanged: (_) {
                  notifier.onValueChange();
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(CupertinoIcons.lock_fill,
                size: 12, color: context.colorScheme.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                context.l10n.profile_form_phone_private,
                style: AppTextStyle.caption
                    .copyWith(color: context.colorScheme.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _label(context.l10n.profile_form_email_label),
        _textField(
          controller: state.emailController,
          focusNode: _emailFocus,
          hint: context.l10n.profile_form_email_hint,
          icon: CupertinoIcons.mail,
          error: errors.contains(ProfileField.email)
              ? context.l10n.profile_form_error_email
              : null,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          onChanged: (_) => notifier.onValueChange(),
        ),
        const SizedBox(height: 14),
        _label(context.l10n.profile_form_location_label),
        _textField(
          controller: state.locationController,
          hint: context.l10n.profile_form_location_hint,
          icon: CupertinoIcons.location,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.addressCity],
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  String _phoneHint(PhoneCountry country) =>
      country.code == 'IN' ? '98765 43210' : '0' * country.minDigits;

  Widget _personalSection(
    EditProfileState state,
    EditProfileViewNotifier notifier,
  ) {
    return _section(
      icon: CupertinoIcons.calendar,
      title: context.l10n.profile_form_section_personal,
      tag: context.l10n.profile_form_optional,
      children: [
        _label(context.l10n.profile_form_dob_label),
        _pickerTile(
          icon: CupertinoIcons.gift,
          text: state.dob?.format(context, DateFormatType.dayMonthYear),
          placeholder: context.l10n.profile_form_dob_add,
          onTap: () => selectDate(
            context,
            helpText: context.l10n.edit_profile_select_birth_date_placeholder,
            initialDate: state.dob ?? DateTime(DateTime.now().year - 20),
            startDate: DateTime(1940),
            endDate: DateTime.now(),
            onDateSelected: (date) => notifier.onDateSelect(selectedDate: date),
          ),
        ),
        const SizedBox(height: 14),
        _label(context.l10n.profile_form_gender_label),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [UserGender.male, UserGender.female, UserGender.other]
              .map((gender) => _chip(
                    gender.getString(context),
                    selected: state.gender == gender,
                    onTap: () => notifier.onGenderSelect(gender: gender),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _cricketSection(
    EditProfileState state,
    EditProfileViewNotifier notifier,
  ) {
    return _section(
      icon: CupertinoIcons.sportscourt_fill,
      title: context.l10n.profile_form_section_cricket,
      tag: context.l10n.profile_form_optional,
      children: [
        _label(context.l10n.profile_form_role_label),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlayerRole.values
              .where((role) => role != PlayerRole.none)
              .map((role) => _chip(
                    role.getString(context),
                    selected: state.playerRole == role,
                    onTap: () => notifier.onPlayerRoleChange(role),
                  ))
              .toList(),
        ),
        const SizedBox(height: 14),
        _label(context.l10n.profile_form_batting_label),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BattingStyle.values
              .map((style) => _chip(
                    style.getString(context),
                    selected: state.battingStyle == style,
                    onTap: () => notifier.onBattingStyleChange(style),
                  ))
              .toList(),
        ),
        const SizedBox(height: 14),
        _label(context.l10n.profile_form_bowling_label),
        _pickerTile(
          icon: CupertinoIcons.circle_grid_hex,
          text: state.bowlingStyle?.getString(context),
          placeholder: context.l10n.profile_form_choose,
          onTap: () => showActionBottomSheet(
            context: context,
            items: BowlingStyle.values
                .map((style) => BottomSheetAction(
                      title: style.getString(context),
                      child: state.bowlingStyle == style
                          ? Icon(CupertinoIcons.checkmark_alt,
                              color: context.colorScheme.primary)
                          : null,
                      onTap: () {
                        context.pop();
                        notifier.onBowlingStyleChange(style);
                      },
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Inputs ───────────────────────────────────────────────────────────────

  Widget _label(String text, {bool required = false}) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text.rich(
        TextSpan(
          text: text,
          style: AppTextStyle.subtitle3.copyWith(
            color: cs.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: AppTextStyle.subtitle3.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    String? error,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    final cs = context.colorScheme;
    return AppTextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      enabled: !ref
          .watch(editProfileStateProvider.select((s) => s.isSaveInProgress)),
      hintText: hint,
      errorText: error,
      prefixIcon: Icon(icon, size: 18, color: cs.textSecondary),
      style: AppTextStyle.subtitle3.copyWith(color: cs.textPrimary),
      hintStyle: AppTextStyle.subtitle3.copyWith(color: cs.textDisabled),
      errorStyle: AppTextStyle.caption.copyWith(color: cs.alert),
      backgroundColor: cs.containerLow,
      borderRadius: BorderRadius.circular(14),
      borderType: AppTextFieldBorderType.outline,
      borderWidth: 1.5,
      borderColor: BorderColor(
        focusColor: error == null ? cs.primary : cs.alert,
        unFocusColor: error == null ? Colors.transparent : cs.alert,
      ),
    );
  }

  Widget _countryButton(
    EditProfileState state,
    EditProfileViewNotifier notifier,
  ) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: () => _pickCountry(state.phoneCountry, notifier),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: cs.containerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.phoneCountry.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              state.phoneCountry.dial,
              style: AppTextStyle.subtitle3.copyWith(
                color: cs.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(CupertinoIcons.chevron_down,
                size: 12, color: cs.textSecondary),
          ],
        ),
      ),
    );
  }

  void _pickCountry(PhoneCountry current, EditProfileViewNotifier notifier) {
    final cs = context.colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  context.l10n.profile_form_country_title,
                  style: AppTextStyle.header4.copyWith(
                    color: cs.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final country in PhoneCountry.all)
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading:
                      Text(country.flag, style: const TextStyle(fontSize: 22)),
                  title: Text(
                    country.name,
                    style:
                        AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        country.dial,
                        style: AppTextStyle.subtitle3
                            .copyWith(color: cs.textSecondary),
                      ),
                      if (country.code == current.code) ...[
                        const SizedBox(width: 8),
                        Icon(CupertinoIcons.checkmark_alt,
                            color: cs.primary, size: 18),
                      ],
                    ],
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    notifier.onPhoneCountryChange(country);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String? text,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cs.containerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subtitle3.copyWith(
                  color: text == null ? cs.textDisabled : cs.textPrimary,
                ),
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                size: 14, color: cs.textDisabled),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, {required bool selected, VoidCallback? onTap}) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.containerLow,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: brandRedColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(CupertinoIcons.checkmark_alt, size: 14, color: cs.onPrimary),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: AppTextStyle.subtitle3.copyWith(
                  color: selected ? cs.onPrimary : cs.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────

  Widget _bottomBar(EditProfileState state, EditProfileViewNotifier notifier) {
    final cs = context.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: brandNavyColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _centered(
            PrimaryButton(
              _creating
                  ? context.l10n.profile_form_create_btn
                  : context.l10n.profile_form_save_btn,
              progress: state.isSaveInProgress,
              enabled: !state.isImageUploading,
              onPressed: () => _submit(notifier),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(EditProfileViewNotifier notifier) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final errors = await notifier.onSubmitTap();
    if (errors.isEmpty || !mounted) return;

    final first = errors.first;
    (switch (first) {
      ProfileField.name => _nameFocus,
      ProfileField.phone => _phoneFocus,
      ProfileField.email => _emailFocus,
    })
        .requestFocus();

    final missingName = errors.contains(ProfileField.name);
    final phoneProblem = errors.contains(ProfileField.phone);
    final message = missingName && phoneProblem
        ? mascotText.mascot_profile_need_both
        : missingName
            ? mascotText.mascot_profile_need_name
            : phoneProblem
                ? notifier.phoneError == PhoneError.empty
                    ? mascotText.mascot_profile_need_phone
                    : mascotText.mascot_profile_bad_phone
                : mascotText.mascot_profile_bad_email;
    ref.read(mascotProvider.notifier).show(
          MascotPose.warning,
          message,
          allowFun: false,
          duration: const Duration(seconds: 6),
        );
  }

  Widget _signOutLink(EditProfileViewNotifier notifier) {
    return Center(
      child: CupertinoButton(
        onPressed: () async {
          await notifier.signOut();
          if (mounted) AppRoute.main.go(context);
        },
        child: Text(
          context.l10n.profile_form_sign_out,
          style: AppTextStyle.subtitle3
              .copyWith(color: context.colorScheme.textSecondary),
        ),
      ),
    );
  }

  Widget _deleteAccount(EditProfileViewNotifier notifier) {
    final cs = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          onPressed: notifier.checkUserOwnershipAndShowDialog,
          context.l10n.edit_profile_delete_account_btn_title,
          background: cs.containerLow,
          foreground: cs.alert,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
          child: Text(
            context.l10n.edit_profile_delete_account_description_text,
            style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
          ),
        ),
      ],
    );
  }

  // ── Mascot and listeners ─────────────────────────────────────────────────

  void _greetName(String name) {
    final first = name.trim().split(' ').first;
    if (first.length < 2) return;
    ref.read(mascotProvider.notifier).show(
          MascotPose.welcome,
          mascotText.mascot_profile_name(first),
          delay: const Duration(milliseconds: 900),
          duration: const Duration(seconds: 3),
        );
  }

  void _observeActionError() {
    ref.listen(editProfileStateProvider.select((value) => value.actionError),
        (previous, next) {
      if (next != null) {
        showErrorSnackBar(context: context, error: next);
        ref.read(mascotProvider.notifier).show(
              MascotPose.error,
              mascotText.mascot_something_wrong,
              allowFun: false,
            );
      }
    });
  }

  void _observeIsSaved() {
    ref.listen(editProfileStateProvider.select((state) => state.isSaved),
        (previous, next) {
      if (!next) return;
      final name = ref
          .read(editProfileStateProvider)
          .nameController
          .text
          .trim()
          .split(' ')
          .first;
      ref.read(mascotProvider.notifier).show(
            _creating ? MascotPose.celebrate : MascotPose.saved,
            _creating
                ? mascotText.mascot_profile_created(name)
                : mascotText.mascot_profile_saved,
          );
      if (_creating) {
        AppRoute.main.go(context);
      } else {
        context.pop();
      }
    });
  }

  void _observeShowDeleteConfirmationDialog(VoidCallback onDeleteTap) {
    ref.listen(
        editProfileStateProvider.select(
            (state) => state.showDeleteConfirmationDialog), (previous, next) {
      if (next) {
        showConfirmationDialog(
          context,
          title: context.l10n.common_delete_title,
          message: context.l10n.alert_confirm_default_message(
              context.l10n.common_delete_title.toLowerCase()),
          confirmBtnText: context.l10n.common_delete_title,
          onConfirm: onDeleteTap,
        );
      }
    });
  }

  void _observeShowTransferTeamsSheet() {
    ref.listen(
        editProfileStateProvider
            .select((state) => state.showTransferTeamsSheet), (previous, next) {
      if (next) {
        TransferTeamsSheet.show(
          context,
          onButtonTap: () {
            context.pop();
            context.pop(true);
          },
        );
      }
    });
  }
}
