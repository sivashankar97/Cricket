import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/error_snackbar.dart';
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
        child: CreatePlayerSheet(initialName: initialName, onCreate: onCreate),
      ),
    );
  }

  final String initialName;
  final Future<void> Function(String name, String? phone) onCreate;

  const CreatePlayerSheet({
    super.key,
    required this.initialName,
    required this.onCreate,
  });

  @override
  State<CreatePlayerSheet> createState() => _CreatePlayerSheetState();
}

class _CreatePlayerSheetState extends State<CreatePlayerSheet> {
  late final TextEditingController _nameController;
  final TextEditingController _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _nameController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _create() async {
    setState(() => _saving = true);
    try {
      final phone = _phoneController.text.trim();
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
          _field(
            context,
            _phoneController,
            context.l10n.add_team_member_create_player_phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            ],
          ),
        ],
      ),
      action: [
        PrimaryButton(
          context.l10n.add_team_member_create_player_button,
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
