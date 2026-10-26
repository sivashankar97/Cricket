import 'package:flutter/material.dart';

import '../text/app_text_style.dart';

// ── iOS HIG System Colors ────────────────────────────────────────────────────

// Primary accent — iOS system blue
const primaryLightColor = Color(0xFF007AFF);
const primaryDarkColor = Color(0xFF0A84FF);

const primaryVariantLightColor = Color(0x26007AFF); // 15% opacity
const primaryVariantDarkColor = Color(0x330A84FF); // 20% opacity

// Secondary — iOS system indigo (for secondary actions)
const secondaryColor = Color(0xFF5856D6);

// Containers — iOS system gray hierarchy (light)
// systemGray6 → systemGray5 → systemGray4
const containerHighLightColor = Color(0x33636366);  // systemGray ~20%
const containerNormalLightColor = Color(0x1F636366); // systemGray ~12%
const containerLowLightColor = Color(0x0F636366);   // systemGray ~6%

// Containers — dark mode equivalents
const containerHighDarkColor = Color(0x3DEBEBF5);
const containerNormalDarkColor = Color(0x29EBEBF5);
const containerLowDarkColor = Color(0x14EBEBF5);

// Text — iOS label hierarchy (light)
const textPrimaryLightColor = Color(0xFF000000);      // label
const textSecondaryLightColor = Color(0x993C3C43);    // secondaryLabel
const textDisabledLightColor = Color(0x4D3C3C43);     // tertiaryLabel

// Text — iOS label hierarchy (dark)
const textPrimaryDarkColor = Color(0xFFFFFFFF);       // label dark
const textSecondaryDarkColor = Color(0x99EBEBF5);     // secondaryLabel dark
const textDisabledDarkColor = Color(0x4DEBEBF5);      // tertiaryLabel dark

// Separators — iOS style
const outlineLightColor = Color(0x293C3C43);          // separator light
const outlineDarkColor = Color(0x29545458);           // separator dark

// Surfaces — iOS system backgrounds
const surfaceLightColor = Color(0xFFFFFFFF);           // systemBackground
const surfaceDarkColor = Color(0xFF000000);            // systemBackground dark

// Grouped background — used for list screens
const groupedBackgroundLightColor = Color(0xFFF2F2F7); // systemGroupedBackground
const groupedBackgroundDarkColor = Color(0xFF1C1C1E);  // systemGroupedBackground dark

// Semantic awareness — aligned to iOS HIG
const awarenessAlertColor = Color(0xFFFF3B30);        // iOS system red
const awarenessPositiveColor = Color(0xFF34C759);     // iOS system green
const awarenessWarningColor = Color(0xFFFF9F0A);      // iOS system orange
const awarenessInfoColor = Color(0xFF007AFF);         // iOS system blue

final ThemeData _materialLightTheme = ThemeData.light(useMaterial3: true);
final ThemeData _materialDarkTheme = ThemeData.dark(useMaterial3: true);

const _pickerInputDecorationTheme = InputDecorationTheme(
  errorBorder: OutlineInputBorder(
    borderSide: BorderSide(color: awarenessAlertColor),
  ),
);

final ThemeData materialThemeDataLight = _materialLightTheme.copyWith(
  primaryColor: primaryLightColor,
  dividerColor: outlineLightColor,
  datePickerTheme: _materialLightTheme.datePickerTheme.copyWith(
    backgroundColor: surfaceLightColor,
    headerForegroundColor: textPrimaryLightColor,
    dividerColor: outlineLightColor,
    inputDecorationTheme: _pickerInputDecorationTheme,
  ),
  timePickerTheme: _materialLightTheme.timePickerTheme.copyWith(
    backgroundColor: surfaceLightColor,
    dialBackgroundColor: containerLowLightColor,
    dayPeriodColor: primaryLightColor,
    hourMinuteColor: containerLowLightColor,
    inputDecorationTheme: _pickerInputDecorationTheme,
  ),
  colorScheme: _materialLightTheme.colorScheme.copyWith(
    primary: primaryLightColor,
    secondary: secondaryColor,
    surface: surfaceLightColor,
    onPrimary: textPrimaryDarkColor,
    onSecondary: textSecondaryDarkColor,
    onSurface: textPrimaryLightColor,
  ),
  scaffoldBackgroundColor: groupedBackgroundLightColor,
  appBarTheme: _materialLightTheme.appBarTheme.copyWith(
    backgroundColor: surfaceLightColor,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: _materialLightTheme.appBarTheme.titleTextStyle?.copyWith(
      fontFamily: AppTextStyle.poppinsFontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 17,
      letterSpacing: -0.4,
      color: textPrimaryLightColor,
      package: 'style',
    ),
  ),
);

final ThemeData materialThemeDataDark = _materialDarkTheme.copyWith(
  primaryColor: primaryDarkColor,
  dividerColor: outlineDarkColor,
  datePickerTheme: _materialDarkTheme.datePickerTheme.copyWith(
    backgroundColor: surfaceDarkColor,
    headerForegroundColor: textPrimaryDarkColor,
    dividerColor: outlineDarkColor,
    inputDecorationTheme: _pickerInputDecorationTheme,
  ),
  timePickerTheme: _materialDarkTheme.timePickerTheme.copyWith(
    backgroundColor: surfaceDarkColor,
    dialBackgroundColor: containerLowDarkColor,
    dayPeriodColor: primaryDarkColor,
    hourMinuteColor: containerLowDarkColor,
    inputDecorationTheme: _pickerInputDecorationTheme,
  ),
  colorScheme: _materialDarkTheme.colorScheme.copyWith(
    primary: primaryDarkColor,
    secondary: secondaryColor,
    surface: surfaceDarkColor,
    onPrimary: textPrimaryDarkColor,
    onSecondary: textSecondaryDarkColor,
    onSurface: textPrimaryDarkColor,
  ),
  scaffoldBackgroundColor: groupedBackgroundDarkColor,
  appBarTheme: _materialDarkTheme.appBarTheme.copyWith(
    backgroundColor: surfaceDarkColor,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: _materialDarkTheme.appBarTheme.titleTextStyle?.copyWith(
      fontFamily: AppTextStyle.poppinsFontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 17,
      letterSpacing: -0.4,
      color: textPrimaryDarkColor,
      package: 'style',
    ),
  ),
);

class AppColorScheme {
  final Color primary;
  final Color primaryVariant;
  final Color secondary;
  final Color surface;
  /// iOS systemGroupedBackground — `#F2F2F7` light / `#1C1C1E` dark.
  final Color groupedBackground;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color textInversePrimary;
  final Color textInverseSecondary;
  final Color textInverseDisabled;
  final Color containerHigh;
  final Color containerNormal;
  final Color containerLow;
  final Color positive;
  final Color alert;
  final Color warning;
  final Color info;
  final Color onPrimary;
  final Color onSecondary;
  final Color onDisabled;
  final ThemeMode themeMode;

  AppColorScheme({
    required this.primary,
    required this.primaryVariant,
    required this.secondary,
    required this.surface,
    required this.groupedBackground,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textInversePrimary,
    required this.textInverseSecondary,
    required this.textInverseDisabled,
    required this.containerHigh,
    required this.containerNormal,
    required this.containerLow,
    required this.positive,
    required this.alert,
    required this.warning,
    required this.info,
    required this.onPrimary,
    required this.onSecondary,
    required this.onDisabled,
    required this.themeMode,
  });

  Color get containerNormalOnSurface =>
      Color.alphaBlend(containerNormal, surface);

  Color get containerHighOnSurface => Color.alphaBlend(containerHigh, surface);

  Color get containerLowOnSurface => Color.alphaBlend(containerLow, surface);

  Color get primaryVariantOnSurface =>
      Color.alphaBlend(primaryVariant, surface);
}

final appColorSchemeLight = AppColorScheme(
  primary: primaryLightColor,
  primaryVariant: primaryVariantLightColor,
  secondary: secondaryColor,
  surface: surfaceLightColor,
  groupedBackground: groupedBackgroundLightColor,
  outline: outlineLightColor,
  textPrimary: textPrimaryLightColor,
  textSecondary: textSecondaryLightColor,
  textDisabled: textDisabledLightColor,
  textInversePrimary: textPrimaryDarkColor,
  textInverseSecondary: textSecondaryDarkColor,
  textInverseDisabled: textDisabledDarkColor,
  containerHigh: containerHighLightColor,
  containerNormal: containerNormalLightColor,
  containerLow: containerLowLightColor,
  positive: awarenessPositiveColor,
  alert: awarenessAlertColor,
  warning: awarenessWarningColor,
  info: awarenessInfoColor,
  onPrimary: textPrimaryDarkColor,
  onSecondary: textSecondaryDarkColor,
  onDisabled: textDisabledLightColor,
  themeMode: ThemeMode.light,
);

final appColorSchemeDark = AppColorScheme(
  primary: primaryDarkColor,
  primaryVariant: primaryVariantDarkColor,
  secondary: secondaryColor,
  surface: surfaceDarkColor,
  groupedBackground: groupedBackgroundDarkColor,
  outline: outlineDarkColor,
  textPrimary: textPrimaryDarkColor,
  textSecondary: textSecondaryDarkColor,
  textDisabled: textDisabledDarkColor,
  textInversePrimary: textPrimaryLightColor,
  textInverseSecondary: textSecondaryLightColor,
  textInverseDisabled: textDisabledLightColor,
  containerHigh: containerHighDarkColor,
  containerNormal: containerNormalDarkColor,
  containerLow: containerLowDarkColor,
  positive: awarenessPositiveColor,
  alert: awarenessAlertColor,
  warning: awarenessWarningColor,
  info: awarenessInfoColor,
  onPrimary: textPrimaryDarkColor,
  onSecondary: textSecondaryDarkColor,
  onDisabled: textDisabledLightColor,
  themeMode: ThemeMode.dark,
);
