import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:data/errors/app_error.dart';
import 'package:data/service/file_upload/file_upload_service.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:data/utils/constant/firebase_storage_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

import 'form_text_field.dart';

/// Add / edit form for a [TeamPool]. Pops with the saved pool id.
class TeamPoolFormSheet extends ConsumerStatefulWidget {
  static Future<String?> show(BuildContext context, {TeamPool? pool}) {
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
        child: TeamPoolFormSheet(pool: pool),
      ),
    );
  }

  final TeamPool? pool;

  const TeamPoolFormSheet({super.key, this.pool});

  @override
  ConsumerState<TeamPoolFormSheet> createState() => _TeamPoolFormSheetState();
}

class _TeamPoolFormSheetState extends ConsumerState<TeamPoolFormSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.pool?.name);
  late final TextEditingController _shortNameController =
      TextEditingController(text: widget.pool?.shortName);
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
      final poolId = widget.pool?.id ?? service.generatePoolId;
      var logo = widget.pool?.logo;
      if (_logoPath != null) {
        if (!await isFileUnderMaxSize(_logoPath!)) {
          throw const LargeAttachmentUploadError();
        }
        logo = await ref.read(fileUploadServiceProvider).uploadProfileImage(
              filePath: _logoPath!,
              uploadPath: StorageConst.teamProfileUploadPath(
                userId: userId,
                teamId: poolId,
              ),
            );
      }
      await service.savePool(
        poolId: poolId,
        userId: userId,
        name: _nameController.text,
        shortName: _shortNameController.text,
        logo: logo,
        isNew: widget.pool == null,
      );
      if (mounted) context.pop(poolId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.l10nMessage(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetWrapper(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.pool == null
                ? context.l10n.team_pools_new_pool
                : context.l10n.team_pools_edit_pool,
            style: AppTextStyle.header3
                .copyWith(color: context.colorScheme.textPrimary),
          ),
          const SizedBox(height: 16),
          ProfileImageAvatar(
            size: 80,
            isLoading: false,
            filePath: _logoPath,
            imageUrl: widget.pool?.logo,
            placeHolderImage: Assets.images.icGallery,
            onEditButtonTap: _pickLogo,
          ),
          const SizedBox(height: 16),
          FormTextField(
            controller: _nameController,
            label: context.l10n.team_pools_name_label,
            autoFocus: widget.pool == null,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          FormTextField(
            controller: _shortNameController,
            label: context.l10n.team_pools_short_name_label,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [LengthLimitingTextInputFormatter(6)],
          ),
        ],
      ),
      options: [if (_error != null) FormErrorText(_error!)],
      action: [
        PrimaryButton(
          widget.pool == null
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
