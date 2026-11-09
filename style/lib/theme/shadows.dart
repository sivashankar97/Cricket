import 'package:flutter/material.dart';

import 'colors.dart';

extension AppSurfaceStyle on AppColorScheme {
  bool get _isDark => themeMode == ThemeMode.dark;

  /// White card on lavender (light) or lighter indigo card on navy (dark).
  Color get card => surface;

  /// Soft indigo lift, as in the Sports Tamil concept cards.
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: (_isDark ? Colors.black : brandNavyColor)
              .withValues(alpha: _isDark ? 0.25 : 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  /// Chips and unselected tabs — no shadow on iOS; bg color does the job.
  List<BoxShadow> get chipShadow => [];

  /// Primary CTA — very faint blue tint, iOS-appropriate (not a red glow).
  List<BoxShadow> get primaryShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.20),
          blurRadius: 8,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ];

  /// iOS tab bars / bottom sheets use a hairline separator, not a shadow.
  List<BoxShadow> get bottomBarShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.04),
          blurRadius: 0.5,
          offset: const Offset(0, -0.5),
        ),
      ];

  BoxDecoration cardDecoration({double radius = 14}) => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: cardShadow,
      );
}
