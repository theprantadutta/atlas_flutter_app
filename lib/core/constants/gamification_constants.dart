import 'package:flutter/material.dart';

class GamificationConstants {
  // Level system
  static const int maxLevel = 100;
  static const int baseXpPerLevel = 100;

  /// Task XP: difficulty x 10 x type_multiplier x streak_bonus
  static int calculateTaskXp({
    required int difficulty,
    required String taskType,
    int streakCount = 0,
  }) {
    double baseXp = difficulty * 10;
    double multiplier = switch (taskType) {
      'daily' => 1.0,
      'weekly' => 1.5,
      'long_term' => 2.0,
      _ => 1.0,
    };
    double streakBonus = 1.0 + (streakCount * 0.10).clamp(0.0, 1.0);
    return (baseXp * multiplier * streakBonus).round();
  }

  /// Habit XP: difficulty x 10 x (1 + streak_bonus)
  static int calculateHabitXp({
    required int difficulty,
    int streakCount = 0,
  }) {
    double baseXp = difficulty * 10;
    double streakBonus = 1.0 + (streakCount * 0.05).clamp(0.0, 0.5);
    return (baseXp * streakBonus).round();
  }

  /// Goal XP: (priority x 100) + (progress x 500)
  static int calculateGoalXp({
    required int priority,
    double progress = 1.0,
  }) {
    return (priority * 100 + progress * 500).round();
  }

  /// XP required to reach a level: 100 x (level-1)^2 x 0.8
  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    return (100.0 * (level - 1) * (level - 1) * 0.8).round();
  }

  /// Calculate level from total XP (max 100)
  static int calculateLevel(int totalXp) {
    int level = 1;
    while (level < maxLevel && totalXp >= xpRequiredForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  // Badge tier colors
  static const Color bronzeColor = Color(0xFFCD7F32);
  static const Color commonColor = Color(0xFFC0C0C0);
  static const Color rareColor = Color(0xFFFFD700);
  static const Color epicColor = Color(0xFFE5E4E2);
  static const Color legendaryColor = Color(0xFFB9F2FF);

  static Color colorForBadgeTier(String tier) {
    switch (tier) {
      case 'bronze':
        return bronzeColor;
      case 'common':
        return commonColor;
      case 'rare':
        return rareColor;
      case 'epic':
        return epicColor;
      case 'legendary':
        return legendaryColor;
      default:
        return bronzeColor;
    }
  }
}
