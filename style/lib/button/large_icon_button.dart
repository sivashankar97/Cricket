import 'package:flutter/cupertino.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';

/// iOS-style large icon button.
///
/// Uses a circular fill; the tint comes from the provided [backgroundColor]
/// (defaults to primary). No shadow — matches iOS HIG icon button pattern.
class LargeIconButton extends StatelessWidget {
  final Color? backgroundColor;
  final Widget icon;
  final double size;
  final bool enabled;
  final bool progress;
  final void Function()? onTap;

  const LargeIconButton({
    super.key,
    this.backgroundColor,
    this.size = 50,
    required this.icon,
    this.onTap,
    this.enabled = true,
    this.progress = false,
  });

  @override
  Widget build(BuildContext context) {
    final tappable = !progress && enabled;

    final bg = backgroundColor ?? context.colorScheme.primary;
    final bgColor = tappable ? bg : bg.withValues(alpha: 0.38);

    return OnTapScale(
      enabled: tappable,
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
        ),
        child: progress ? const AppProgressIndicator() : icon,
      ),
    );
  }
}
