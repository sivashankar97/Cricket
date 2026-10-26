import 'package:flutter/material.dart';
import 'package:style/animations/app_animations.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

/// iOS-style segmented tab pill.
///
/// Selected:   solid primary fill.
/// Unselected: transparent with secondary-colored label.
/// The parent scrollable row acts like an iOS segmented control.
class TabButton extends StatelessWidget {
  final Function() onTap;
  final String text;
  final GlobalKey? globalKey;
  final bool selected;

  const TabButton(
    this.text, {
    super.key,
    required this.onTap,
    this.globalKey,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: onTap,
      child: AnimatedContainer(
        key: globalKey,
        duration: AppAnimations.normal,
        curve: AppAnimations.curve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: AppTextStyle.subtitle2.copyWith(
            color: selected ? cs.onPrimary : cs.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
