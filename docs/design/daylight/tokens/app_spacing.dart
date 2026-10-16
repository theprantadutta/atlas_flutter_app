import 'package:flutter/widgets.dart';

/// Spacing, radii and sizing tokens (4 / 8 base). Daylight additions marked NEW.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Radii
  static const double radiusSm = 12;
  static const double radiusIcon = 14; // NEW icon tiles
  static const double radiusMd = 18;
  static const double radiusButton = 20; // NEW list buttons, suggestion cards
  static const double radiusRow = 22; // NEW rows
  static const double radiusLg = 24;
  static const double radiusTile = 26; // NEW tiles, week strip
  static const double radiusChart = 30; // NEW chart card
  static const double radiusXl = 32; // hero + letter cards
  static const double radiusPill = 999;

  static const double gutter = 20;
  static const double headerInset = 4; // NEW extra inset for headers

  // Nav (NEW)
  static const double navHeight = 64;
  static const double navBottom = 26;
  static const double navSide = 16;
  static const double fabSize = 64;
  static const double fabGap = 10;
  static const double navActivePillHeight = 48;

  /// Scroll padding so content clears the floating nav (64 + 26 + 24).
  static const double bottomNavSpace = 114;

  static const double rowHeight = 64; // Home rows
  static const double habitRowHeight = 70; // Grow rows
  static const double iconButton = 44;
  static const double backButton = 42;

  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapLg = SizedBox(width: lg);
}
