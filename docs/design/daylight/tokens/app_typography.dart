import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Atlas "Daylight" type system.
///
/// Funnel Display (tight, confident) for titles and numbers; Funnel Sans for
/// everything else. If your google_fonts version lacks these families, bundle
/// the TTFs in assets/fonts/ and swap GoogleFonts.x(...) for
/// TextStyle(fontFamily: 'FunnelDisplay', ...).
class AppTypography {
  AppTypography._();

  static TextStyle display({
    double size = 40,
    FontWeight weight = FontWeight.w700,
    double? spacingEm,
    double height = 1.0,
    Color? color,
  }) {
    final em = spacingEm ?? _defaultTracking(size);
    return GoogleFonts.funnelDisplay(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: size * em,
      height: height,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Bigger = tighter. Matches the design reference.
  static double _defaultTracking(double size) {
    if (size >= 90) return -0.06;
    if (size >= 60) return -0.05;
    if (size >= 38) return -0.04;
    if (size >= 32) return -0.035;
    if (size >= 26) return -0.03;
    return -0.02;
  }

  static TextStyle sans({double size = 15, FontWeight weight = FontWeight.w400, double height = 1.3, Color? color, double spacingEm = 0}) =>
      GoogleFonts.funnelSans(fontSize: size, fontWeight: weight, height: height, color: color, letterSpacing: size * spacingEm);

  // Named roles
  static TextStyle get heroNumber => display(size: 96, height: .78);
  static TextStyle get statNumber => display(size: 64, height: .85);
  static TextStyle get screenTitle => display(size: 40);
  static TextStyle get greeting => display(size: 34);
  static TextStyle get letterHeadline => display(size: 32, weight: FontWeight.w600, height: 1.05);
  static TextStyle get subScreenTitle => display(size: 30);
  static TextStyle get cardNumber => display(size: 28);
  static TextStyle get section => display(size: 21, height: 1.1);
  static TextStyle get rowTitle => sans(size: 15, weight: FontWeight.w700);
  static TextStyle get body => sans(size: 15, height: 1.55);
  static TextStyle get button => sans(size: 14, weight: FontWeight.w700, height: 1);
  static TextStyle get chip => sans(size: 13, weight: FontWeight.w700, height: 1);
  static TextStyle get meta => sans(size: 12, weight: FontWeight.w600);
  static TextStyle get kicker => sans(size: 12, weight: FontWeight.w800, height: 1, spacingEm: .12);
  static TextStyle get dayLabel => sans(size: 11, weight: FontWeight.w700, height: 1);

  static TextTheme get textTheme => TextTheme(
        displayLarge: heroNumber,
        displayMedium: statNumber,
        displaySmall: screenTitle,
        headlineLarge: greeting,
        headlineMedium: letterHeadline,
        headlineSmall: subScreenTitle,
        titleLarge: section,
        titleMedium: rowTitle,
        titleSmall: sans(size: 14, weight: FontWeight.w700),
        bodyLarge: body,
        bodyMedium: sans(size: 14, height: 1.5),
        bodySmall: meta,
        labelLarge: button,
        labelMedium: chip,
        labelSmall: dayLabel,
      );
}
