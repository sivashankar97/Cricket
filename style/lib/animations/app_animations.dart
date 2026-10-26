import 'package:flutter/material.dart';

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 480);

  static const Curve curve = Curves.easeOutCubic;
  static const Curve reverseCurve = Curves.easeInCubic;
}

extension AnimatedPageController on PageController {
  Future<void> animateToTab(int page) => animateToPage(
        page,
        duration: AppAnimations.normal,
        curve: AppAnimations.curve,
      );
}
