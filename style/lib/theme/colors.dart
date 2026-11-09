import 'package:flutter/material.dart';

import '../text/app_text_style.dart';

// ── Sports Tamil palette, taken from the logo: navy, red, white ─────────────

// Brand navy
const brandNavyColor = Color(0xFF010127);
const brandNavyCardColor = Color(0xFF12124A);
const brandNavyBarColor = Color(0xFF0A0A3A);

// Brand red (live / selected / primary actions)
const brandRedColor = Color(0xFFF9151D);
const brandRedDeepColor = Color(0xFFB30A12);

/// Success only (sold, fours/sixes, done); the logo itself has no green.
const positiveGreenColor = Color(0xFF22C55E);

/// Live-match hero card.
const liveCardGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [brandRedColor, brandRedDeepColor],
);

// Primary accent
const primaryLightColor = brandRedColor;
const primaryDarkColor = brandRedColor;

const primaryVariantLightColor = Color(0x26F9151D);
const primaryVariantDarkColor = Color(0x33F9151D);

const secondaryColor = brandRedColor;

// Containers — navy tints (light)
const containerHighLightColor = Color(0x2E010127);
const containerNormalLightColor = Color(0x1C010127);
const containerLowLightColor = Color(0x0F010127);

// Containers — white tints over navy (dark)
const containerHighDarkColor = Color(0x3DFFFFFF);
const containerNormalDarkColor = Color(0x26FFFFFF);
const containerLowDarkColor = Color(0x14FFFFFF);

// Text (light)
const textPrimaryLightColor = brandNavyColor;
const textSecondaryLightColor = Color(0x99010127);
const textDisabledLightColor = Color(0x52010127);

// Text (dark)
const textPrimaryDarkColor = Color(0xFFFFFFFF);
const textSecondaryDarkColor = Color(0xB3D9D9F0);
const textDisabledDarkColor = Color(0x66D9D9F0);

// Separators
const outlineLightColor = Color(0x29010127);
const outlineDarkColor = Color(0x29FFFFFF);

// Surfaces (cards)
const surfaceLightColor = Color(0xFFFFFFFF);
const surfaceDarkColor = brandNavyCardColor;

// Screen backgrounds
const groupedBackgroundLightColor = Color(0xFFF3F3F8);
const groupedBackgroundDarkColor = brandNavyColor;

// Semantic awareness
const awarenessAlertColor = brandRedColor;
const awarenessPositiveColor = positiveGreenColor;
const awarenessWarningColor = Color(0xFFFF9F0A);
const awarenessInfoColor = Color(0xFF2F4FD8);

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
    backgroundColor: groupedBackgroundLightColor,
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
    backgroundColor: groupedBackgroundDarkColor,
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
  info: const Color(0xFF8FA2FF),
  onPrimary: textPrimaryDarkColor,
  onSecondary: textSecondaryDarkColor,
  onDisabled: textDisabledLightColor,
  themeMode: ThemeMode.dark,
);
