import 'package:data/api/match/match_model.dart';
import 'package:flutter/material.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/flow/matches/add_match/components/section_title.dart';
import 'package:style/button/chip_button.dart';
import 'package:style/button/toggle_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

class MatchRulesView extends StatelessWidget {
  final MatchRules rules;
  final ValueChanged<MatchRules> onChanged;

  /// Balls per over can't change once scoring has started.
  final bool ballsPerOverLocked;
  final bool showTitle;
  final double horizontalPadding;

  const MatchRulesView({
    super.key,
    required this.rules,
    required this.onChanged,
    this.ballsPerOverLocked = false,
    this.showTitle = true,
    this.horizontalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) SectionTitle(title: context.l10n.match_rules_title),
        _optionRow<int>(
          context,
          title: context.l10n.match_rules_balls_per_over_title,
          options: MatchRules.ballsPerOverOptions,
          selected: rules.balls_per_over,
          enabled: !ballsPerOverLocked,
          onSelect: (value) => onChanged(rules.copyWith(balls_per_over: value)),
        ),
        _optionRow<int>(
          context,
          title: context.l10n.match_rules_wide_runs_title,
          options: MatchRules.wideRunOptions,
          selected: rules.wide_runs,
          onSelect: (value) => onChanged(rules.copyWith(wide_runs: value)),
        ),
        _optionRow<int>(
          context,
          title: context.l10n.match_rules_no_ball_runs_title,
          options: MatchRules.noBallRunOptions,
          selected: rules.no_ball_runs,
          onSelect: (value) => onChanged(rules.copyWith(no_ball_runs: value)),
        ),
        _toggleRow(
          context,
          key: ValueKey('wide_rebowl_${rules.wide_rebowl}'),
          title: context.l10n.match_rules_wide_rebowl_title,
          description: context.l10n.match_rules_wide_rebowl_description,
          value: rules.wide_rebowl,
          onChanged: (value) => onChanged(rules.copyWith(wide_rebowl: value)),
        ),
        _toggleRow(
          context,
          key: ValueKey('free_hit_${rules.free_hit}'),
          title: context.l10n.match_rules_free_hit_title,
          description: context.l10n.match_rules_free_hit_description,
          value: rules.free_hit,
          onChanged: (value) => onChanged(rules.copyWith(free_hit: value)),
        ),
        _toggleRow(
          context,
          key: ValueKey('lms_${rules.last_man_standing}'),
          title: context.l10n.match_rules_last_man_standing_title,
          description: context.l10n.match_rules_last_man_standing_description,
          value: rules.last_man_standing,
          onChanged: (value) =>
              onChanged(rules.copyWith(last_man_standing: value)),
        ),
      ],
    );
  }

  Widget _optionRow<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T selected,
    required ValueChanged<T> onSelect,
    bool enabled = true,
  }) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyle.subtitle2
                .copyWith(color: context.colorScheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map((option) => ChipButton(
                        title: option.toString(),
                        isSelected: option == selected,
                        onTap: enabled ? () => onSelect(option) : null,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required Key key,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.subtitle2
                      .copyWith(color: context.colorScheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyle.caption
                      .copyWith(color: context.colorScheme.textDisabled),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          KeyedSubtree(
            key: key,
            child: toggleButton(
              context,
              defaultEnabled: value,
              onTap: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
