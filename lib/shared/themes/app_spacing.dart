import 'package:flutter/widgets.dart';

/// Spacing, radii and sizing tokens on a 4 / 8 base scale.
///
/// Use these instead of inline magic numbers so rhythm stays consistent across
/// the app. Naming follows a t-shirt scale.
class AppSpacing {
  AppSpacing._();

  // ─── Spacing scale (4 / 8 base) ───
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // ─── Corner radii (soft, organic) ───
  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusPill = 999;

  // ─── Screen gutters ───
  static const double gutter = 20;

  // ─── Common SizedBox helpers (vertical) ───
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);

  // ─── Common SizedBox helpers (horizontal) ───
  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapLg = SizedBox(width: lg);
}
