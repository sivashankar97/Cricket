import 'package:flutter/material.dart';
import 'package:style/extensions/context_extensions.dart';

import '../animations/app_animations.dart';
import '../animations/on_tap_scale.dart';
import '../text/app_text_style.dart';

/// iOS-style segmented / pill chip button.
///
/// Selected state: solid primary fill with white label.
/// Unselected state: system gray background with secondary text.
/// No shadows — relies entirely on color for affordance.
class ChipButton extends StatelessWidget {
  final bool isSelected;
  final String title;
  final VoidCallback? onTap;

  const ChipButton({
    super.key,
    this.isSelected = false,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.curve,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary
              // iOS systemGray6 feel for unselected chips
              : cs.containerLowOnSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: AppTextStyle.subtitle2.copyWith(
            color: isSelected ? cs.onPrimary : cs.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
