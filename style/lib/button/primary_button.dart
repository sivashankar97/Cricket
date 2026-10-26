import 'package:flutter/material.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/indicator/progress_indicator.dart';

import '../text/app_text_style.dart';
import '../theme/theme.dart';

/// iOS-style filled primary button.
///
/// - Rounded rectangle (radius 14) — matches iOS pill buttons
/// - No floating shadow; relies on color contrast
/// - Faint opacity reduction when disabled (iOS convention)
class PrimaryButton extends StatelessWidget {
  final String text;
  final EdgeInsets edgeInsets;
  final bool expanded;
  final bool progress;
  final bool enabled;
  final Color? foreground;
  final Color? background;
  final Function()? onPressed;

  const PrimaryButton(
    this.text, {
    super.key,
    this.onPressed,
    this.edgeInsets =
        const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
    this.expanded = true,
    this.enabled = true,
    this.progress = false,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = appColorSchemeOf(context);
    final tappable = !progress && enabled;

    final bg = background ?? colorScheme.primary;
    // iOS dims the button to ~38% when disabled, no color blend needed.
    final bgColor = tappable ? bg : bg.withValues(alpha: 0.38);

    final fg = foreground ?? colorScheme.onPrimary;
    final fgColor = tappable ? fg : fg.withValues(alpha: 0.6);

    return OnTapScale(
      onTap: () => onPressed?.call(),
      enabled: tappable,
      child: Container(
        width: expanded ? double.infinity : null,
        constraints: const BoxConstraints(
          minHeight: 50,
          minWidth: 88,
        ),
        padding: edgeInsets,
        decoration: BoxDecoration(
          color: bgColor,
          // iOS uses radius 14 for most buttons, 10 for compact ones.
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (progress) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: AppProgressIndicator(
                  size: AppProgressIndicatorSize.small,
                  color: fgColor,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              text,
              style: AppTextStyle.button.copyWith(color: fgColor),
            ),
          ],
        ),
      ),
    );
  }
}
