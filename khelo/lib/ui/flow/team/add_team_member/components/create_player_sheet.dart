import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/player_phone_field.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/flow/score_board/components/bottom_sheet_wrapper.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';

class CreatePlayerSheet extends StatefulWidget {
  static Future<bool?> show(
    BuildContext context, {
    String initialName = '',
    String initialPhone = '',
    String? Function(String phone)? phoneError,
    required Future<void> Function(String name, String? phone) onCreate,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: false,
      enableDrag: false,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colorScheme.surface,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CreatePlayerSheet(
          initialName: initialName,
          initialPhone: initialPhone,
          phoneError: phoneError,
          onCreate: onCreate,
        ),
      ),
    );
  }

  final String initialName;
  final String initialPhone;

  /// Message for a number that can't be used, or null when it's fine.
  final String? Function(String phone)? phoneError;
  final Future<void> Function(String name, String? phone) onCreate;

  const CreatePlayerSheet({
    super.key,
    required this.initialName,
    this.initialPhone = '',
    this.phoneError,
    required this.onCreate,
  });

  @override
  State<CreatePlayerSheet> createState() => _CreatePlayerSheetState();
}

class _CreatePlayerSheetState extends State<CreatePlayerSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _saving = false;
  String? _phoneErrorText;
  PlayerPhoneMatch _match = PlayerPhoneMatch.none;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _nameController.addListener(_onChanged);
    _phoneController.addListener(() {
      if (_phoneErrorText != null) setState(() => _phoneErrorText = null);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _onPhoneMatch(PlayerPhoneMatch match) {
    final name = match.player?.name;
    if (name != null && name.isNotEmpty) _nameController.text = name;
    setState(() => _match = match);
  }

  Future<void> _create() async {
    final phone = _phoneController.text.trim();
    final error = phone.isEmpty ? null : widget.phoneError?.call(phone);
    if (error != null) {
      setState(() => _phoneErrorText = error);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onCreate(
          _nameController.text.trim(), phone.isEmpty ? null : phone);
      if (mounted) context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnackBar(context: context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetWrapper(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.add_team_member_create_player_title,
            style: AppTextStyle.header3
                .copyWith(color: context.colorScheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.add_team_member_create_player_description,
            style: AppTextStyle.subtitle2
                .copyWith(color: context.colorScheme.textSecondary),
          ),
          const SizedBox(height: 16),
          _field(
            context,
            _nameController,
            context.l10n.add_team_member_create_player_name,
            autoFocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          PlayerPhoneField(
            controller: _phoneController,
            onChanged: _onPhoneMatch,
          ),
          if (_phoneErrorText != null) ...[
            const SizedBox(height: 6),
            Text(
              _phoneErrorText!,
              style: AppTextStyle.caption
                  .copyWith(color: context.colorScheme.alert),
            ),
          ],
        ],
      ),
      action: [
        PrimaryButton(
          _match.player != null
              ? context.l10n
                  .player_phone_add_existing(_match.player!.name ?? '')
              : context.l10n.add_team_member_create_player_button,
          enabled: _nameController.text.trim().isNotEmpty,
          progress: _saving,
          onPressed: _create,
        ),
      ],
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool autoFocus = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      autoFocus: autoFocus,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      borderRadius: BorderRadius.circular(12),
      borderType: AppTextFieldBorderType.outline,
      style: AppTextStyle.subtitle3
          .copyWith(color: context.colorScheme.textPrimary),
      borderColor: BorderColor(
        focusColor: context.colorScheme.outline,
        unFocusColor: context.colorScheme.outline,
      ),
    );
  }
}
