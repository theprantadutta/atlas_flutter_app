import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/widgets/xp_gain_overlay.dart';
import 'package:atlas_flutter_app/shared/widgets/level_up_overlay.dart';
import 'package:atlas_flutter_app/shared/widgets/achievement_unlock_overlay.dart';

/// Manages full-screen overlay entries for gamification feedback:
/// XP gain, level up, and achievement unlock.
class OverlayService {
  OverlayService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayState? get _overlay =>
      navigatorKey.currentState?.overlay;

  // ─── XP Gain ─────────────────────────────────────────────────────

  static void showXpGain({
    required int xp,
    int? streakBonus,
  }) {
    final overlay = _overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => XpGainOverlay(
        xp: xp,
        streakBonus: streakBonus,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  // ─── Level Up ────────────────────────────────────────────────────

  static void showLevelUp({required int newLevel}) {
    final overlay = _overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => LevelUpOverlay(
        newLevel: newLevel,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  // ─── Achievement Unlock ──────────────────────────────────────────

  static void showAchievementUnlock({
    required String title,
    required String tier,
  }) {
    final overlay = _overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AchievementUnlockOverlay(
        title: title,
        tier: tier,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}
