import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:data/errors/app_error.dart';
import 'package:data/service/file_upload/file_upload_service.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:data/utils/constant/firebase_storage_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/action_bottom_sheet.dart';
import 'package:khelo/components/image_picker_sheet.dart';
import 'package:khelo/components/profile_image_avatar.dart';
import 'package:khelo/domain/extensions/app_error_extension.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/file_extension.dart';
import 'package:khelo/gen/assets.gen.dart';
import 'package:khelo/ui/flow/score_board/components/bottom_sheet_wrapper.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/widgets/adaptive_outlined_tile.dart';

import 'form_text_field.dart';

/// Add / edit form for a [TournamentTeam]. Pops with the saved team id.
class TournamentTeamFormSheet extends ConsumerStatefulWidget {
  /// [poolId] is the pool a new team is created in; edits keep the team's pool.
  static Future<String?> show(
    BuildContext context, {
    TournamentTeam? team,
    String? poolId,
    List<TournamentTeamPlayer> players = const [],
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: false,
      enableDrag: false,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colorScheme.surface,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: TournamentTeamFormSheet(
          team: team,
          poolId: poolId,
          players: players,
        ),
      ),
    );
  }

  final TournamentTeam? team;
  final String? poolId;
  final List<TournamentTeamPlayer> players;

  const TournamentTeamFormSheet({
    super.key,
    this.team,
    this.poolId,
    this.players = const [],
  });

  @override
  ConsumerState<TournamentTeamFormSheet> createState() =>
      _TournamentTeamFormSheetState();
}

class _TournamentTeamFormSheetState
    extends ConsumerState<TournamentTeamFormSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.team?.name);
  late final TextEditingController _shortNameController =
      TextEditingController(text: widget.team?.shortName);
  late String? _captainId = widget.team?.captainId;
  String? _logoPath;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final path = await ImagePickerSheet.show<String>(context, allowCrop: true);
    if (path != null) setState(() => _logoPath = path);
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserPod)?.id;
    if (userId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final service = ref.read(tournamentTeamServiceProvider);
      final teamId = widget.team?.id ?? service.generateTeamId;
      var logo = widget.team?.logo;
      if (_logoPath != null) {
        if (!await isFileUnderMaxSize(_logoPath!)) {
          throw const LargeAttachmentUploadError();
        }
        logo = await ref.read(fileUploadServiceProvider).uploadProfileImage(
              filePath: _logoPath!,
              uploadPath: StorageConst.teamProfileUploadPath(
                userId: userId,
                teamId: teamId,
              ),
            );
      }
      await service.saveTeam(
        teamId: teamId,
        userId: userId,
        name: _nameController.text,
        poolId: widget.team != null ? widget.team!.poolId : widget.poolId,
        shortName: _shortNameController.text,
        logo: logo,
        isNew: widget.team == null,
      );
      if (widget.team != null && _captainId != widget.team!.captainId) {
        await service.setCaptain(teamId, _captainId);
      }
      if (mounted) context.pop(teamId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.l10nMessage(context);
      });
    }
  }

  void _selectCaptain() {
    showActionBottomSheet(
      context: context,
      items: widget.players
          .map((player) => BottomSheetAction(
                title: player.name,
                child: player.id == _captainId
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
                  setState(() => _captainId =
                      player.id == _captainId ? null : player.id);
                },
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final captain =
        widget.players.where((player) => player.id == _captainId).firstOrNull;

    return BottomSheetWrapper(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.team == null
                ? context.l10n.tournament_teams_add_team
                : context.l10n.tournament_teams_edit_team,
            style: AppTextStyle.header3
                .copyWith(color: context.colorScheme.textPrimary),
          ),
          const SizedBox(height: 16),
          ProfileImageAvatar(
            size: 80,
            isLoading: false,
            filePath: _logoPath,
            imageUrl: widget.team?.logo,
            placeHolderImage: Assets.images.icGallery,
            onEditButtonTap: _pickLogo,
          ),
          const SizedBox(height: 16),
          FormTextField(
            controller: _nameController,
            label: context.l10n.tournament_team_name_label,
            autoFocus: widget.team == null,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          FormTextField(
            controller: _shortNameController,
            label: context.l10n.tournament_team_short_name_label,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [LengthLimitingTextInputFormatter(5)],
          ),
          if (widget.players.isNotEmpty) ...[
            const SizedBox(height: 12),
            AdaptiveOutlinedTile(
              headerText: context.l10n.tournament_team_captain_label,
              placeholder: context.l10n.tournament_team_captain_placeholder,
              title: captain?.name,
              showTrailingIcon: true,
              onTap: _selectCaptain,
            ),
          ],
        ],
      ),
      options: [if (_error != null) FormErrorText(_error!)],
      action: [
        PrimaryButton(
          widget.team == null
              ? context.l10n.common_create
              : context.l10n.common_save_title,
          enabled: _nameController.text.trim().isNotEmpty,
          progress: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
