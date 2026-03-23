import 'package:flutter/services.dart';

/// Convenience wrapper around [HapticFeedback] for consistent haptic
/// feedback across the app.
class HapticUtils {
  HapticUtils._();

  /// Light impact — for taps and selections.
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact — for toggles and confirmations.
  static void mediumTap() {
    HapticFeedback.mediumImpact();
  }

  /// Success vibration — for task completion, XP gain, etc.
  static void successVibrate() {
    HapticFeedback.heavyImpact();
  }
}
