import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary - Deep Blue (exploration/adventure) ───
  static const primary = Color(0xFF1E3A5F);
  static const primaryLight = Color(0xFF2E5A8F);
  static const primaryDark = Color(0xFF0F1F35);

  // ─── Secondary - Teal/Cyan (growth/progress) ───
  static const secondary = Color(0xFF0891B2);
  static const secondaryLight = Color(0xFF22D3EE);
  static const secondaryDark = Color(0xFF065F7C);

  // ─── Tertiary - Amber/Gold (achievement/reward) ───
  static const tertiary = Color(0xFFF59E0B);
  static const tertiaryLight = Color(0xFFFBBF24);
  static const tertiaryDark = Color(0xFFD97706);

  // ─── XP Colors ───
  static const xpPrimary = Color(0xFF10B981);
  static const xpSecondary = Color(0xFF34D399);
  static const xpBackground = Color(0xFFD1FAE5);

  // ─── Streak ───
  static const streakFlame = Color(0xFFEF4444);
  static const streakGlow = Color(0xFFFCA5A5);

  // ─── Badge Tiers ───
  static const badgeBronze = Color(0xFFCD7F32);
  static const badgeCommon = Color(0xFF9CA3AF);
  static const badgeRare = Color(0xFF3B82F6);
  static const badgeEpic = Color(0xFF8B5CF6);
  static const badgeLegendary = Color(0xFFF97316);

  // ─── Category Colors ───
  static const categoryHealth = Color(0xFFEF4444);
  static const categoryFitness = Color(0xFFF97316);
  static const categoryMindfulness = Color(0xFF8B5CF6);
  static const categoryFinance = Color(0xFF10B981);
  static const categoryWork = Color(0xFF3B82F6);
  static const categoryLearning = Color(0xFF6366F1);
  static const categorySocial = Color(0xFFEC4899);
  static const categoryCreative = Color(0xFFF59E0B);

  // ─── Surfaces - Light ───
  static const surfaceLight = Color(0xFFF8FAFC);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardBorderLight = Color(0xFFE2E8F0);

  // ─── Surfaces - Dark ───
  static const surfaceDark = Color(0xFF0F172A);
  static const cardDark = Color(0xFF1E293B);
  static const cardBorderDark = Color(0xFF334155);

  // ─── Text ───
  static const textPrimaryLight = Color(0xFF0F172A);
  static const textSecondaryLight = Color(0xFF64748B);
  static const textPrimaryDark = Color(0xFFF1F5F9);
  static const textSecondaryDark = Color(0xFF94A3B8);

  // ─── Status ───
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ─── Gradients ───
  static const primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
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
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const streakGradient = LinearGradient(
    colors: [streakFlame, Color(0xFFF97316)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}
