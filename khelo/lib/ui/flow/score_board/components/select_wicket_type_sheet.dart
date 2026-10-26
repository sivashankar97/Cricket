import 'package:data/api/ball_score/ball_score_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/ui/flow/score_board/components/bottom_sheet_wrapper.dart';
import 'package:khelo/ui/flow/score_board/score_board_view_model.dart';
import 'package:style/button/chip_button.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';

/// Dismissals still possible on a free hit.
const freeHitWicketTypes = [
  WicketType.runOut,
  WicketType.hitBallTwice,
  WicketType.obstructingField,
  WicketType.handledBall,
  WicketType.retired,
  WicketType.retiredHurt,
];

class SelectWicketTypeSheet extends ConsumerStatefulWidget {
  static Future<T?> show<T>(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      showDragHandle: false,
      enableDrag: false,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colorScheme.surface,
      builder: (context) {
        return const SelectWicketTypeSheet();
      },
    );
  }

  const SelectWicketTypeSheet({super.key});

  @override
  ConsumerState createState() => _SelectWicketTypeSheetState();
}

class _SelectWicketTypeSheetState extends ConsumerState<SelectWicketTypeSheet> {
  WicketType? selectedType;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scoreBoardStateProvider);

    return BottomSheetWrapper(
      content: _typeList(context, state),
      action: [
        PrimaryButton(
          context.l10n.common_okay_title,
          enabled: selectedType != null,
          onPressed: () => context.pop(selectedType),
        )
      ],
    );
  }

  Widget _typeList(
    BuildContext context,
    ScoreBoardViewState state,
  ) {
    final types = ref.read(scoreBoardStateProvider.notifier).isFreeHit
        ? WicketType.values.where((type) => freeHitWicketTypes.contains(type))
        : WicketType.values;
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 8,
      runSpacing: 8,
      children: types.map(
        (element) {
          final isSelected = selectedType == element;
          return ChipButton(
            isSelected: isSelected,
            title: element.getString(context),
            onTap: () => setState(() => selectedType = element),
          );
        },
      ).toList(),
    );
  }
}
