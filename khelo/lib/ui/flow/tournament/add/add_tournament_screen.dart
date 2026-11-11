import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/api/match/match_model.dart';
import 'package:data/api/tournament/tournament_details.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/components/mascot/mascot_reactions.dart';
import 'package:khelo/components/profile_image_avatar.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:khelo/ui/flow/matches/add_match/components/section_title.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/platform/local_file_image.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/extensions/widget_extension.dart';
import 'package:khelo/gen/assets.gen.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/tournament/add/add_tournament_view_model.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/button/action_button.dart';
import 'package:style/button/bottom_sticky_overlay.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/pickers/date_and_time_picker.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/widgets/adaptive_outlined_tile.dart';

import '../../../../components/action_bottom_sheet.dart';
import '../../../../components/app_page.dart';
import '../../../../components/confirmation_dialog.dart';
import '../../../../components/error_snackbar.dart';
import '../../../../components/image_picker_sheet.dart';
import '../../../../domain/formatter/date_formatter.dart';
import '../team_picker/tournament_team_picker_view_model.dart';

class AddTournamentScreen extends ConsumerStatefulWidget {
  final TournamentModel? editTournament;

  const AddTournamentScreen({super.key, this.editTournament});

  @override
  ConsumerState<AddTournamentScreen> createState() =>
      _AddTournamentScreenState();
}

class _AddTournamentScreenState extends ConsumerState<AddTournamentScreen> {
  late AddTournamentViewNotifier notifier;

  @override
  void initState() {
    super.initState();
    notifier = ref.read(addTournamentStateProvider.notifier);
    runPostFrame(() => notifier.setData(widget.editTournament));
  }

  void _observeActionError(BuildContext context, WidgetRef ref) {
    ref.listen(addTournamentStateProvider.select((value) => value.actionError),
        (previous, next) {
      if (next != null) {
        showErrorSnackBar(context: context, error: next);
      }
    });
  }

  void _observePop(BuildContext context, WidgetRef ref) {
    ref.listen(addTournamentStateProvider.select((value) => value.pop),
        (previous, next) {
      if (next) {
        ref
            .read(mascotProvider.notifier)
            .react(MascotReaction.tournamentCreated);
        context.pop();
      }
    });
  }

  void _observeDateError(BuildContext context, WidgetRef ref) {
    ref.listen(
        addTournamentStateProvider.select((value) => value.showDateError),
        (previous, next) {
      showErrorSnackBar(
          context: context, error: context.l10n.add_tournament_date_error);
    });
  }

  @override
  Widget build(BuildContext context) {
    _observeActionError(context, ref);
    _observeDateError(context, ref);
    _observePop(context, ref);

    final state = ref.watch(addTournamentStateProvider);
    final isOrganizer = widget.editTournament == null ||
        (state.currentUserId == widget.editTournament?.created_by ||
            widget.editTournament!.members
                .any((e) => e.id == state.currentUserId && e.role.isOrganizer));

    return AppPage(
      title: widget.editTournament == null
          ? context.l10n.add_tournament_screen_title
          : context.l10n.tournament_detail_edit_title,
      actions: (widget.editTournament != null && isOrganizer)
          ? [
              actionButton(
                context,
                onPressed: () => showConfirmationDialog(
                  context,
                  title: context.l10n.add_tournament_delete_title,
                  message: context.l10n.add_tournament_delete_description,
                  confirmBtnText: context.l10n.common_delete_title,
                  onConfirm: () async {
                    if (!await notifier.deleteTournament()) return;
                    if (!context.mounted) return;
                    context.pop();
                    context.pop();
                  },
                ),
                icon: SvgPicture.asset(
                  Assets.images.icBin,
                  height: 24,
                  width: 24,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                      context.colorScheme.alert, BlendMode.srcATop),
                ),
              )
            ]
          : null,
      body: Builder(
        builder: (context) => Stack(
          children: [
            _body(context, isOrganizer, state),
            _stickyButton(context, state),
          ],
        ),
      ),
    );
  }

  Widget _body(
      BuildContext context, bool isOrganizer, AddTournamentState state) {
    return ListView(
      padding: context.mediaQueryPadding +
          BottomStickyOverlay.padding +
          const EdgeInsets.only(bottom: 24),
      children: [
        _bannerView(context, state),
        const SizedBox(height: 16),
        _inputField(
          context,
          controller: state.nameController,
          hintText: context.l10n.add_tournament_name,
          enabled: isOrganizer,
        ),
        SectionTitle(
          title: context.l10n.add_tournament_type,
          trailing: _typeButton(context, state, isOrganizer),
        ),
        _teamsCard(context, state, isOrganizer),
        SectionTitle(title: context.l10n.add_tournament_venue_title),
        _inputField(
          context,
          controller: notifier.groundController,
          hintText: context.l10n.add_tournament_ground,
          enabled: isOrganizer,
        ),
        const SizedBox(height: 16),
        _inputField(
          context,
          controller: notifier.cityController,
          hintText: context.l10n.add_tournament_city,
          enabled: isOrganizer,
        ),
        SectionTitle(title: context.l10n.add_tournament_match_format_title),
        _oversCard(context, isOrganizer),
        _ballTypeView(context, isOrganizer),
        SectionTitle(title: context.l10n.add_tournament_schedule_title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _dateScheduleView(context, state),
        ),
      ],
    );
  }

  Widget _inputField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppTextField(
        controller: controller,
        enabled: enabled,
        hintText: hintText,
        hintStyle: AppTextStyle.subtitle3
            .copyWith(color: context.colorScheme.textDisabled),
        style: AppTextStyle.subtitle3
            .copyWith(color: context.colorScheme.textPrimary),
        onChanged: (_) => notifier.onChange(),
        borderRadius: BorderRadius.circular(12),
        borderType: AppTextFieldBorderType.outline,
        borderColor: BorderColor(
          focusColor: context.colorScheme.outline,
          unFocusColor: context.colorScheme.outline,
        ),
      ),
    );
  }

  Widget _typeButton(
    BuildContext context,
    AddTournamentState state,
    bool isOrganizer,
  ) {
    final cs = context.colorScheme;
    return OnTapScale(
      enabled: isOrganizer,
      onTap: () => _selectTypeSheet(
        context,
        selectedType: state.selectedType,
        onSelected: notifier.onSelectType,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.selectedType.getString(context),
              style: AppTextStyle.body2.copyWith(color: cs.onPrimary),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              Assets.images.icArrowDown,
              height: 18,
              width: 18,
              colorFilter: ColorFilter.mode(cs.onPrimary, BlendMode.srcATop),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTeams(AddTournamentState state) async {
    final result = await AppRoute.tournamentTeamPicker(
      selectedTeams: state.teams,
    ).push<TournamentTeamPickerResult>(context);
    if (mounted && result != null) {
      notifier.onSelectTeam(result.teams, poolId: result.poolId);
    }
  }

  /// Same look as the team A vs team B card in Add Match.
  Widget _teamsCard(
    BuildContext context,
    AddTournamentState state,
    bool isOrganizer,
  ) {
    final cs = context.colorScheme;
    const maxAvatars = 5;
    final teams = state.teams;
    final extra = teams.length - maxAvatars;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OnTapScale(
        enabled: isOrganizer,
        onTap: () => _pickTeams(state),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: cs.containerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (teams.isEmpty)
                Container(
                  height: 80,
                  width: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.containerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, size: 32, color: cs.textDisabled),
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final team in teams.take(maxAvatars))
                      SizedBox(
                        width: 64,
                        child: Column(
                          children: [
                            ImageAvatar(
                              initial: team.name_initial ??
                                  team.name.initials(limit: 2),
                              imageUrl: team.profile_img_url,
                              size: 56,
                              backgroundColor: cs.containerHigh,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              team.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTextStyle.caption
                                  .copyWith(color: cs.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    if (extra > 0)
                      Container(
                        height: 56,
                        width: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.containerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '+$extra',
                          style: AppTextStyle.subtitle1
                              .copyWith(color: cs.textSecondary),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Text(
                teams.isEmpty
                    ? context.l10n.team_selection_select_team_title
                    : context.l10n.add_tournament_teams_title(teams.length),
                style: AppTextStyle.subtitle3.copyWith(color: cs.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                teams.isEmpty
                    ? context.l10n.add_tournament_teams_hint
                    : context.l10n.add_tournament_change_teams,
                textAlign: TextAlign.center,
                style: AppTextStyle.button.copyWith(
                  color: teams.isEmpty ? cs.textDisabled : cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Stepper card like "No. of overs" in Add Match.
  Widget _oversCard(BuildContext context, bool isOrganizer) {
    final cs = context.colorScheme;
    final overs = int.tryParse(notifier.oversController.text) ?? 0;

    void step(int delta) {
      final next = (overs + delta).clamp(1, TournamentDetails.maxOvers);
      setState(() => notifier.oversController.text = next.toString());
      notifier.onChange();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.add_tournament_overs,
              style: AppTextStyle.subtitle3.copyWith(color: cs.textPrimary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: cs.containerLowOnSurface,
            ),
            child: Row(
              children: [
                _stepperButton(
                  context,
                  icon: Icons.remove,
                  enabled: isOrganizer && overs > 1,
                  onTap: () => step(-1),
                ),
                Material(
                  color: Colors.transparent,
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: notifier.oversController,
                      enabled: isOrganizer,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.header4.copyWith(color: cs.primary),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: '0',
                        hintStyle:
                            AppTextStyle.header4.copyWith(color: cs.primary),
                      ),
                      onChanged: (_) => setState(notifier.onChange),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                ),
                _stepperButton(
                  context,
                  icon: Icons.add,
                  enabled: isOrganizer && overs < TournamentDetails.maxOvers,
                  onTap: () => step(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(
    BuildContext context, {
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: onTap,
      enabled: enabled,
      child: Container(
        height: 34,
        width: 34,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: cs.surface, shape: BoxShape.circle),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? cs.textPrimary : cs.textDisabled,
        ),
      ),
    );
  }

  /// Ball cards with images, like Add Match.
  Widget _ballTypeView(BuildContext context, bool isOrganizer) {
    final cs = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: context.l10n.add_tournament_ball_type),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: BallType.values.map((type) {
              final selected = notifier.ballType == type;
              return OnTapScale(
                enabled: isOrganizer,
                onTap: () => setState(() => notifier.onBallType(type)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  margin: const EdgeInsets.only(right: 16),
                  constraints: const BoxConstraints(minWidth: 121),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? cs.primary : cs.outline,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: selected
                        ? cs.containerLowOnSurface
                        : Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        _ballImage(type),
                        height: 40,
                        width: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type.getString(context),
                        textAlign: TextAlign.center,
                        style: AppTextStyle.subtitle3
                            .copyWith(color: cs.textPrimary),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _ballImage(BallType type) {
    switch (type) {
      case BallType.leather:
        return Assets.images.leatherBall;
      case BallType.tennis:
        return Assets.images.tennisBall;
      case BallType.other:
        return Assets.images.otherBall;
    }
  }

  Widget _bannerView(BuildContext context, AddTournamentState state) {
    final bool hasBannerImage =
        state.bannerPath != null || state.bannerImgUrl != null;

    return Stack(
      children: [
        Container(
          height: 204,
          width: context.mediaQuerySize.width,
          margin: EdgeInsets.only(bottom: 45),
          decoration: BoxDecoration(
            color: context.colorScheme.containerLow,
            image: state.bannerPath != null
                ? DecorationImage(
                    image: localFileImage(state.bannerPath!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (state.imageUploading) Center(child: AppProgressIndicator()),
              if (!state.imageUploading)
                hasBannerImage
                    ? _buildCachedNetworkOrFileImage(context, state)
                    : _bannerPlaceholder(context,
                        onTap: () => _pickImage(isBanner: true)),
              if (hasBannerImage && !state.imageUploading)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _editBannerButton(context),
                ),
            ],
          ),
        ),
        _profileView(context, state),
      ],
    );
  }

  Widget _buildCachedNetworkOrFileImage(
      BuildContext context, AddTournamentState state) {
    if (state.bannerPath != null) {
      return Image(
        image: localFileImage(state.bannerPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (state.bannerImgUrl != null) {
      return CachedNetworkImage(
        imageUrl: state.bannerImgUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return SizedBox.shrink(); // Fallback if neither image is available
  }

  Widget _editBannerButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _pickImage(isBanner: true),
      icon: SvgPicture.asset(
        Assets.images.icCamera,
        colorFilter: ColorFilter.mode(
          context.colorScheme.surface,
          BlendMode.srcATop,
        ),
      ),
      label: Text(
        context.l10n.add_tournament_edit_banner,
        style:
            AppTextStyle.caption.copyWith(color: context.colorScheme.surface),
      ),
      style: TextButton.styleFrom(
        backgroundColor: context.colorScheme.textDisabled,
      ),
    );
  }

  void _pickImage({bool isBanner = false}) async {
    final imagePath = await ImagePickerSheet.show<String>(
      context,
      allowCrop: true,
      cropOriginal: isBanner,
    );
    if (imagePath != null) {
      notifier.onImageChange(imagePath: imagePath, isBanner: isBanner);
    }
  }

  Widget _bannerPlaceholder(
    BuildContext context, {
    required Function() onTap,
  }) {
    return OnTapScale(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SvgPicture.asset(
          Assets.images.icCamera,
          colorFilter: ColorFilter.mode(
            context.colorScheme.textDisabled,
            BlendMode.srcATop,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.add_tournament_add_banner_placeholder,
          style: AppTextStyle.caption.copyWith(
            color: context.colorScheme.textDisabled,
          ),
        ),
      ]),
    );
  }

  Widget _stickyButton(
    BuildContext context,
    AddTournamentState state,
  ) {
    return BottomStickyOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!notifier.details.isComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                context.l10n.add_tournament_details_required(
                    TournamentDetails.maxOvers),
                textAlign: TextAlign.center,
                style: AppTextStyle.caption
                    .copyWith(color: context.colorScheme.textSecondary),
              ),
            ),
          PrimaryButton(
            widget.editTournament == null
                ? context.l10n.common_create
                : context.l10n.common_edit,
            progress: state.loading,
            enabled: state.enableButton,
            onPressed: notifier.addTournament,
          ),
        ],
      ),
    );
  }

  Widget _profileView(BuildContext context, AddTournamentState state) {
    return Positioned(
      left: 16,
      bottom: 0,
      child: ProfileImageAvatar(
        size: 90,
        isLoading: state.imageUploading && state.profilePath == null,
        filePath: state.profilePath,
        imageUrl: state.profileImgUrl,
        placeHolderImage: Assets.images.icTournaments,
        alignment: Alignment.centerLeft,
        onEditButtonTap: _pickImage,
      ),
    );
  }

  Widget _dateScheduleView(
    BuildContext context,
    AddTournamentState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AdaptiveOutlinedTile(
                  title: state.startDate.format(context, DateFormatType.date),
                  headerImage: Assets.images.icCalendar,
                  headerText: context.l10n.add_tournament_start_date,
                  placeholder: context.l10n.add_tournament_start_date,
                  onTap: () {
                    selectDate(
                      context,
                      startDate: widget.editTournament?.start_date,
                      initialDate: state.startDate,
                      onDateSelected: notifier.onStartDate,
                    );
                  }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AdaptiveOutlinedTile(
                  title: state.endDate.format(context, DateFormatType.date),
                  headerImage: Assets.images.icCalendar,
                  headerText: context.l10n.add_tournament_end_date,
                  placeholder: context.l10n.add_tournament_end_date,
                  onTap: () {
                    selectDate(
                      context,
                      startDate: widget.editTournament?.start_date,
                      initialDate: state.endDate,
                      onDateSelected: notifier.onEndDate,
                    );
                  }),
            ),
          ],
        ),
      ],
    );
  }

  void _selectTypeSheet(
    BuildContext context, {
    required TournamentType selectedType,
    required Function(TournamentType) onSelected,
  }) {
    showActionBottomSheet(
      context: context,
      heightFactor: 0.8,
      items: TournamentType.values
          .map(
            (type) => BottomSheetAction(
              title: type.getString(context),
              subTitle: type.getDescriptionString(context),
              enabled: selectedType != type,
              child: (selectedType == type)
                  ? SvgPicture.asset(
                      Assets.images.icCheck,
                      colorFilter: ColorFilter.mode(
                        context.colorScheme.primary,
                        BlendMode.srcATop,
                      ),
                    )
                  : null,
              onTap: () {
                context.pop();
                onSelected.call(type);
              },
            ),
          )
          .toList(),
    );
  }
}
