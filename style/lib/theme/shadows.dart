import 'package:flutter/material.dart';

import 'colors.dart';

extension AppSurfaceStyle on AppColorScheme {
  bool get _isDark => themeMode == ThemeMode.dark;

  /// iOS-style card background: white on grouped gray (light) or
  /// elevated dark surface (dark). Relies on bg separation, not shadow.
  Color get card => _isDark ? const Color(0xFF1C1C1E) : surface;

  /// iOS cards use no floating shadow — just a hairline border or bg contrast.
  /// Very subtle single-layer shadow only in dark mode for slight lift.
  List<BoxShadow> get cardShadow => _isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 1,
            offset: const Offset(0, 0.5),
          ),
        ]
      : [];

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

  /// iOS-standard card decoration: radius 10, white bg, no shadow.
  BoxDecoration cardDecoration({double radius = 10}) => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: cardShadow,
      );
}
