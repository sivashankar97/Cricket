import 'package:flutter/material.dart';

/// iOS HIG–aligned type scale using Poppins.
///
/// Mapping to SF Pro / iOS HIG equivalents:
///   header1   → Large Title        (34pt, w700)
///   header2   → Title 1            (28pt, w700)
///   header3   → Title 2            (22pt, w700)
///   header4   → Title 3            (20pt, w600)
///   navTitle  → Navigation Bar     (17pt, w600) — iOS nav bar standard
///   subtitle1 → Headline           (17pt, w600)
///   subtitle2 → Subheadline medium (15pt, w500)
///   subtitle3 → Subheadline reg    (15pt, w400)
///   body1     → Body               (17pt, w400)
///   body2     → Callout            (16pt, w400)
///   button    → Callout Bold       (17pt, w600)
///   caption   → Caption 1          (12pt, w400)
class AppTextStyle {
  static const String poppinsFontFamily = 'Poppins';

  // ── Large Title (top of scrollable view) ───────────────────────────────────
  static const TextStyle header1 = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 34,
    letterSpacing: 0.37,
    height: 1.2,
    package: 'style',
  );

  // ── Title 1 ────────────────────────────────────────────────────────────────
  static const TextStyle header2 = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    letterSpacing: 0.36,
    height: 1.21,
    package: 'style',
  );

  // ── Title 2 ────────────────────────────────────────────────────────────────
  static const TextStyle header3 = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    letterSpacing: 0.35,
    height: 1.22,
    package: 'style',
  );

  // ── Title 3 ────────────────────────────────────────────────────────────────
  static const TextStyle header4 = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: 0.38,
    height: 1.25,
    package: 'style',
  );

  // ── Navigation Bar Title (iOS: 17pt semibold, tight tracking) ──────────────
  static const TextStyle navTitle = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    letterSpacing: -0.41,
    height: 1.29,
    package: 'style',
  );

  // ── Headline ────────────────────────────────────────────────────────────────
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    letterSpacing: -0.41,
    height: 1.29,
    package: 'style',
  );

  // ── Subheadline (medium weight) ─────────────────────────────────────────────
  static const TextStyle subtitle2 = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    letterSpacing: -0.24,
    height: 1.33,
    package: 'style',
  );

  // ── Subheadline (regular weight) ────────────────────────────────────────────
  static const TextStyle subtitle3 = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.normal,
    fontSize: 15,
    letterSpacing: -0.24,
    height: 1.33,
    package: 'style',
  );

  // ── Body ────────────────────────────────────────────────────────────────────
  static const TextStyle body1 = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.normal,
    fontSize: 17,
    letterSpacing: -0.41,
    height: 1.29,
    package: 'style',
  );

  // ── Callout ─────────────────────────────────────────────────────────────────
  static const TextStyle body2 = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: -0.32,
    height: 1.31,
    package: 'style',
  );

  // ── Button / CTA ────────────────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    letterSpacing: -0.41,
    height: 1.29,
    package: 'style',
  );

  // ── Caption 1 ───────────────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontFamily: poppinsFontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0,
    height: 1.33,
    package: 'style',
  );
}
