import 'package:flutter/material.dart';

/// Atlas — "Living World / Aurora" palette.
///
/// Dark is the hero (twilight ink). The aurora gradient (teal → lilac → rose)
/// is the single bold accent, used sparingly for sky / hero / progress. Warm
/// gold marks rewards. Category / tile / tier hues are kept natural and lightly
/// desaturated so the whole app reads as one living world rather than a rainbow.
///
/// NOTE: the public token names are stable — widgets across the app reference
/// them directly. Values change with the redesign; names do not.
class AppColors {
  AppColors._();

  // ─── Aurora signature (the one bold accent) ───
  static const auroraTeal = Color(0xFF5EEAD4);
  static const auroraLilac = Color(0xFF8B9CF7);
  static const auroraRose = Color(0xFFF5A9C0);

  // ─── Primary - periwinkle/lilac (the calm brand) ───
  static const primary = Color(0xFF6E7BF2);
  static const primaryLight = Color(0xFF8B9CF7);
  static const primaryDark = Color(0xFF4A55C7);

  // ─── Secondary - aurora teal (growth/progress) ───
  static const secondary = Color(0xFF2BB6A6);
  static const secondaryLight = Color(0xFF5EEAD4);
  static const secondaryDark = Color(0xFF1E8C80);

  // ─── Tertiary - warm gold (achievement/reward) ───
  static const tertiary = Color(0xFFE8A765);
  static const tertiaryLight = Color(0xFFF4C77B);
  static const tertiaryDark = Color(0xFFC9863F);

  // ─── XP / growth ───
  static const xpPrimary = Color(0xFF34D6A8);
  static const xpSecondary = Color(0xFF6EE7C7);
  static const xpBackground = Color(0xFFD7F5EC);

  // ─── Streak (warm momentum, not aggressive red) ───
  static const streakFlame = Color(0xFFF2994A);
  static const streakGlow = Color(0xFFF9C784);

  // ─── Badge Tiers (natural, still clearly tiered) ───
  static const badgeBronze = Color(0xFFC0855A);
  static const badgeCommon = Color(0xFF98A2B8);
  static const badgeRare = Color(0xFF6E9BE6);
  static const badgeEpic = Color(0xFFAB8BE0);
  static const badgeLegendary = Color(0xFFF0B45C);

  // ─── Category Colors (muted, living-world) ───
  static const categoryHealth = Color(0xFFE2725B);
  static const categoryFitness = Color(0xFFE8965A);
  static const categoryMindfulness = Color(0xFF9B8BE0);
  static const categoryFinance = Color(0xFF5BB58C);
  static const categoryWork = Color(0xFF6E8FD6);
  static const categoryLearning = Color(0xFF7C84E8);
  static const categorySocial = Color(0xFFE58AAE);
  static const categoryCreative = Color(0xFFE5B45C);

  // ─── Surfaces - Light (warm "dawn paper") ───
  static const surfaceLight = Color(0xFFF6F3EC);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardBorderLight = Color(0xFFE7E1D5);

  // ─── Surfaces - Dark (twilight ink) ───
  static const surfaceDark = Color(0xFF0E1326);
  static const surfaceHighDark = Color(0xFF1E2742);
  static const cardDark = Color(0xFF171E38);
  static const cardBorderDark = Color(0xFF2A3350);

  // ─── Text ───
  static const textPrimaryLight = Color(0xFF1A1F2E);
  static const textSecondaryLight = Color(0xFF6A7185);
  static const textPrimaryDark = Color(0xFFEAEEFB);
  static const textSecondaryDark = Color(0xFF9AA6C8);

  // ─── Status ───
  static const success = Color(0xFF5BB58C);
  static const warning = Color(0xFFE8A765);
  static const error = Color(0xFFE0685F);
  static const info = Color(0xFF6E8FD6);

  // ─── Gradients ───
  /// The signature aurora sweep — teal → lilac → rose.
  static const auroraGradient = LinearGradient(
    colors: [auroraTeal, auroraLilac, auroraRose],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const primaryGradient = LinearGradient(
    colors: [primaryDark, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const xpGradient = LinearGradient(
    colors: [xpPrimary, xpSecondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const goldGradient = LinearGradient(
    colors: [tertiary, tertiaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [secondaryDark, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const streakGradient = LinearGradient(
    colors: [streakFlame, streakGlow],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  // ─── Light Mode Gradients ───
  static const primaryGradientLight = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradientLight = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Returns the appropriate primary gradient based on brightness.
  static LinearGradient heroPrimaryGradient(bool isDark) =>
      isDark ? primaryGradient : primaryGradientLight;

  /// Returns the appropriate secondary gradient based on brightness.
  static LinearGradient heroSecondaryGradient(bool isDark) =>
      isDark ? secondaryGradient : secondaryGradientLight;

  // ─── Time-of-day sky stops (for the Living Horizon) ───
  /// Sky gradient stops keyed to the hour, so the world shifts dawn → night.
  static List<Color> skyForHour(int hour) {
    if (hour >= 5 && hour < 8) {
      // dawn — soft rose & amber
      return const [Color(0xFF2A2547), Color(0xFF6E5C8E), Color(0xFFF5B79C)];
    } else if (hour >= 8 && hour < 17) {
      // day — calm teal & lilac
      return const [Color(0xFF153244), Color(0xFF2E6E8E), Color(0xFF7FD7C9)];
    } else if (hour >= 17 && hour < 20) {
      // dusk — the aurora hour
      return const [Color(0xFF1A1B30), Color(0xFF6A4E8E), Color(0xFFF2A8B6)];
    } else {
      // night — deep ink & faint aurora
      return const [Color(0xFF080B1A), Color(0xFF1B2347), Color(0xFF3A4E8C)];
    }
  }

  /// Airy sky stops for light mode — keeps the living horizon feeling bright and
  /// "dawn paper" rather than carrying dark-mode weight.
  static List<Color> skyForHourLight(int hour) {
    if (hour >= 5 && hour < 8) {
      // dawn — soft blue → blush → peach
      return const [Color(0xFFBBD2EE), Color(0xFFE6CFDD), Color(0xFFFBE3C8)];
    } else if (hour >= 8 && hour < 17) {
      // day — clear, airy
      return const [Color(0xFFAFD6EE), Color(0xFFCDE9E3), Color(0xFFE9F3DE)];
    } else if (hour >= 17 && hour < 20) {
      // dusk — gentle lavender & peach
      return const [Color(0xFFBAC6EC), Color(0xFFE0CFE2), Color(0xFFF7DAC6)];
    } else {
      // night (light theme) — soft dusky lavender, still bright
      return const [Color(0xFFAEB8DE), Color(0xFFC8C5E2), Color(0xFFDDD2E2)];
    }
  }
}
