import 'package:flutter/material.dart';

import 'app_animations.dart';

/// Entrance delays for list items: 40 ms per item, capped at 8 items so long
/// lists don't drag.
class AppStagger {
  static const Duration step = Duration(milliseconds: 40);
  static const int maxItems = 8;

  static Duration of(int index) =>
      step * (index < 0 ? 0 : (index > maxItems ? maxItems : index));
}

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Counts a number up from 0 on first build, then animates between values.
/// The final text equals [format] of [value].
class CountUp extends StatelessWidget {
  final num value;
  final int decimals;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// Formats the shown value; defaults to [decimals] fixed digits.
  final String Function(num value)? format;

  const CountUp({
    super.key,
    required this.value,
    this.decimals = 0,
    this.style,
    this.textAlign,
    this.format,
  });

  String _text(num v) => format != null
      ? format!(decimals == 0 ? v.round() : v)
      : v.toStringAsFixed(decimals);

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) {
      return Text(_text(value), style: style, textAlign: textAlign);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: AppAnimations.slow * 2,
      curve: AppAnimations.curve,
      builder: (context, v, _) => Text(
        _text(v),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

/// A horizontal bar that grows from 0 to [fraction] (0–1) of the width.
class GrowBar extends StatelessWidget {
  final double fraction;
  final Color color;
  final Color? trackColor;
  final double height;
  final Duration delay;

  const GrowBar({
    super.key,
    required this.fraction,
    required this.color,
    this.trackColor,
    this.height = 6,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final target = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height / 2);
    Widget bar(double f) => Container(
          height: height,
          decoration: BoxDecoration(
            color: trackColor ?? color.withValues(alpha: 0.14),
            borderRadius: radius,
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: f,
            child: Container(
              decoration: BoxDecoration(color: color, borderRadius: radius),
            ),
          ),
        );
    if (_reduceMotion(context)) return bar(target);
    final total = delay + AppAnimations.slow * 2;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, _) {
        final start = delay.inMilliseconds / total.inMilliseconds;
        final local = t <= start ? 0.0 : (t - start) / (1 - start);
        return bar(target * AppAnimations.curve.transform(local));
      },
    );
  }
}

/// Reveals [child] from the left edge, like [GrowBar] for any content
/// (e.g. a stacked bar made of several segments).
class GrowIn extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const GrowIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return child;
    final total = delay + AppAnimations.slow * 2;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      child: child,
      builder: (context, t, child) {
        final start = delay.inMilliseconds / total.inMilliseconds;
        final local = t <= start ? 0.0 : (t - start) / (1 - start);
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: AppAnimations.curve.transform(local),
            child: child,
          ),
        );
      },
    );
  }
}
