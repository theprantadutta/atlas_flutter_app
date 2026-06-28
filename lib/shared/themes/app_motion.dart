import 'package:flutter/widgets.dart';

/// Motion tokens — "calm by default, joyful at milestones".
///
/// Standard durations and curves so animation feels coherent. Always gate
/// ambient / looping motion behind [reduceMotion] to respect the OS setting.
class AppMotion {
  AppMotion._();

  // ─── Durations ───
  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 360);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration deliberate = Duration(milliseconds: 900);

  /// Ambient loops (e.g. the aurora drift) — long and gentle.
  static const Duration ambient = Duration(seconds: 14);

  // ─── Curves ───
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve gentle = Curves.easeInOut;
  static const Curve celebrate = Curves.elasticOut;

  /// Whether the user prefers reduced motion (disable animations / ambient loops).
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
