import 'package:flutter/material.dart';

/// Atlas "Daylight" type system.
///
/// Funnel Display (tight, confident) for titles and numbers; Funnel Sans for
/// everything else. Both are bundled under `assets/fonts/` so type renders
/// identically offline, on first launch and in golden tests.
///
/// Styles carry no color: the theme applies `textPrimary`, and widgets that
/// need another color take it from `context.palette`.
class AppTypography {
  AppTypography._();

  static const displayFamily = 'FunnelDisplay';
  static const sansFamily = 'FunnelSans';

  static const _tabular = [FontFeature.tabularFigures()];

  /// Funnel Display. Tracking defaults to the size ladder in the spec
  /// (bigger = tighter); pass [spacingEm] to override.
  static TextStyle display({
    double size = 40,
    FontWeight weight = FontWeight.w700,
    double? spacingEm,
    double height = 1.0,
    Color? color,
  }) {
    final em = spacingEm ?? _defaultTracking(size);
    return TextStyle(
      fontFamily: displayFamily,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: size * em,
      height: height,
      color: color,
      fontFeatures: _tabular,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  static double _defaultTracking(double size) {
    if (size >= 90) return -0.06;
    if (size >= 60) return -0.05;
    if (size >= 38) return -0.04;
    if (size >= 32) return -0.035;
    if (size >= 26) return -0.03;
    return -0.02;
  }

  /// Funnel Sans.
  static TextStyle sans({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    double height = 1.3,
    Color? color,
    double spacingEm = 0,
    bool tabular = false,
    FontStyle? fontStyle,
  }) =>
      TextStyle(
        fontFamily: sansFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
        fontStyle: fontStyle,
        letterSpacing: size * spacingEm,
        fontFeatures: tabular ? _tabular : null,
        leadingDistribution: TextLeadingDistribution.even,
      );

  // ─── Named roles (see README "Typography") ───
  static TextStyle get heroNumber => display(size: 96, height: .78);
  static TextStyle get statNumber => display(size: 64, height: .85);
  static TextStyle get screenTitle => display(size: 40);
  static TextStyle get greeting => display(size: 34);
  static TextStyle get letterHeadline =>
      display(size: 32, weight: FontWeight.w600, height: 1.05);
  static TextStyle get subScreenTitle => display(size: 30);
  static TextStyle get cardNumber => display(size: 28);
  static TextStyle get section => display(size: 21, height: 1.1);
  static TextStyle get chatName => display(size: 19, height: 1.1);
  static TextStyle get rowTitle => sans(size: 15, weight: FontWeight.w700);
  static TextStyle get tileTitle => sans(size: 13, weight: FontWeight.w700);
  static TextStyle get body => sans(size: 15, height: 1.55);
  static TextStyle get bubble => sans(size: 15, height: 1.45);
  static TextStyle get subtitle => sans(size: 15, weight: FontWeight.w600);
  static TextStyle get dateLine => sans(size: 14, weight: FontWeight.w600);
  static TextStyle get button => sans(size: 14, weight: FontWeight.w700, height: 1);
  static TextStyle get navLabel => sans(size: 14, weight: FontWeight.w800, height: 1);
  static TextStyle get chip => sans(size: 13, weight: FontWeight.w700, height: 1);
  static TextStyle get meta =>
      sans(size: 12, weight: FontWeight.w600, tabular: true);
  static TextStyle get metaStrong =>
      sans(size: 12, weight: FontWeight.w700, tabular: true);
  static TextStyle get kicker =>
      sans(size: 12, weight: FontWeight.w800, height: 1, spacingEm: .12);
  static TextStyle get dayLabel =>
      sans(size: 11, weight: FontWeight.w700, height: 1);
  static TextStyle get tiny =>
      sans(size: 11, weight: FontWeight.w600, tabular: true);
  static TextStyle get pinLabel =>
      sans(size: 11, weight: FontWeight.w800, height: 1);

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
