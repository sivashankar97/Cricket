import 'package:flutter/material.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

/// iOS-style tinted secondary button.
///
/// Shows the primary color as text on a lightly tinted background —
/// matching iOS's "tinted" button style (Settings, App Store, etc.).
class SecondaryButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final Function()? onPressed;

  const SecondaryButton(
    this.text, {
    super.key,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final textColor = enabled
        ? cs.primary
        : cs.primary.withValues(alpha: 0.38);
    // iOS tinted bg: ~15% opacity of the primary color
    final bgColor = cs.primary.withValues(alpha: enabled ? 0.10 : 0.05);

    return OnTapScale(
      onTap: onPressed,
      enabled: enabled,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: AppTextStyle.button.copyWith(color: textColor),
        ),
      ),
    );
  }
}
