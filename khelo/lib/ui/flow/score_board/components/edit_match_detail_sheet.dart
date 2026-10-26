import 'package:data/api/match/match_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/flow/matches/add_match/components/match_rules_view.dart';
import 'package:khelo/ui/flow/score_board/components/bottom_sheet_wrapper.dart';
import 'package:khelo/ui/flow/score_board/score_board_view_model.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';

class EditMatchDetailSheet extends ConsumerStatefulWidget {
  static Future<T?> show<T>(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      showDragHandle: false,
      enableDrag: false,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colorScheme.surface,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const EditMatchDetailSheet(),
      ),
    );
  }

  const EditMatchDetailSheet({super.key});

  @override
  ConsumerState createState() => _EditMatchDetailSheetState();
}

class _EditMatchDetailSheetState extends ConsumerState<EditMatchDetailSheet> {
  late final TextEditingController _overController;
  late final TextEditingController _overPerBowlerController;
  late final TextEditingController _groundController;
  late final TextEditingController _cityController;
  late MatchRules _rules;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final match = ref.read(scoreBoardStateProvider).match;
    _overController =
        TextEditingController(text: "${match?.number_of_over ?? ''}");
    _overPerBowlerController =
        TextEditingController(text: "${match?.over_per_bowler ?? ''}");
    _groundController = TextEditingController(text: match?.ground ?? '');
    _cityController = TextEditingController(text: match?.city ?? '');
    _rules = match?.rules ?? const MatchRules();
  }

  @override
  void dispose() {
    _overController.dispose();
    _overPerBowlerController.dispose();
    _groundController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      (int.tryParse(_overController.text.trim()) ?? 0) > 0 &&
      (int.tryParse(_overPerBowlerController.text.trim()) ?? 0) > 0 &&
      _groundController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved =
        await ref.read(scoreBoardStateProvider.notifier).updateMatchDetails(
              numberOfOver: int.parse(_overController.text.trim()),
              overPerBowler: int.parse(_overPerBowlerController.text.trim()),
              city: _cityController.text.trim(),
              ground: _groundController.text.trim(),
              rules: _rules,
            );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(scoreBoardStateProvider.notifier);
    return BottomSheetWrapper(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.score_board_edit_match_title,
            style: AppTextStyle.header3
                .copyWith(color: context.colorScheme.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _field(
                  context,
                  _overController,
                  context.l10n.add_match_no_of_over_title,
                  numeric: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  context,
                  _overPerBowlerController,
                  context.l10n.add_match_over_per_bowler_title,
                  numeric: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(context, _groundController,
              context.l10n.add_match_ground_title),
          const SizedBox(height: 12),
          _field(context, _cityController, context.l10n.common_city_title),
          const SizedBox(height: 24),
          Text(
            context.l10n.match_rules_title,
            style: AppTextStyle.header4
                .copyWith(color: context.colorScheme.textPrimary),
          ),
          MatchRulesView(
            rules: _rules,
            showTitle: false,
            horizontalPadding: 0,
            ballsPerOverLocked: notifier.hasBallsBowled,
            onChanged: (rules) => setState(() => _rules = rules),
          ),
        ],
      ),
      action: [
        PrimaryButton(
          context.l10n.common_save_title,
          enabled: _isValid,
          progress: _saving,
          onPressed: _save,
        ),
      ],
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool numeric = false,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      borderRadius: BorderRadius.circular(12),
      borderType: AppTextFieldBorderType.outline,
      style: AppTextStyle.subtitle3
          .copyWith(color: context.colorScheme.textPrimary),
      borderColor: BorderColor(
        focusColor: context.colorScheme.outline,
        unFocusColor: context.colorScheme.outline,
      ),
      keyboardType: numeric ? TextInputType.number : null,
      inputFormatters:
          numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
      onChanged: (_) => setState(() {}),
    );
  }
}
