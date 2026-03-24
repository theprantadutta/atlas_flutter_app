import 'package:flutter/material.dart';

class GamificationConstants {
  // XP rewards
  static const int baseTaskXp = 25;
  static const int dailyTaskXp = 25;
  static const int weeklyTaskXp = 75;
  static const int longTermTaskXp = 150;

  // Difficulty multipliers
  static const double easyMultiplier = 0.8;
  static const double mediumMultiplier = 1.0;
  static const double hardMultiplier = 1.5;

  // Streak bonuses
  static const double streakBonusPerDay = 0.1;
  static const double maxStreakBonus = 2.0;

  // Level system
  static const int maxLevel = 100;
  static const int baseXpPerLevel = 100;
  static const double levelScalingFactor = 1.5;

  /// Calculate XP required for a given level.
  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    return (baseXpPerLevel * level * (1 + (level - 1) * 0.1)).round();
  }

  /// Calculate cumulative XP needed to reach a level.
  static int cumulativeXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i <= level; i++) {
      total += xpRequiredForLevel(i);
    }
    return total;
  }

  /// Calculate level from total XP.
  static int levelFromXp(int totalXp) {
    int level = 1;
    int cumulativeXp = 0;
    while (level < maxLevel) {
      cumulativeXp += xpRequiredForLevel(level + 1);
      if (cumulativeXp > totalXp) break;
      level++;
    }
    return level;
  }

  /// Calculate XP reward for a task based on type and difficulty.
  static int calculateTaskXp({
    required String taskType,
    int difficulty = 1,
    int streakCount = 0,
  }) {
    int baseXp;
    switch (taskType) {
      case 'daily':
        baseXp = dailyTaskXp;
        break;
      case 'weekly':
        baseXp = weeklyTaskXp;
        break;
      case 'long_term':
        baseXp = longTermTaskXp;
        break;
      default:
        baseXp = baseTaskXp;
    }

    double difficultyMultiplier;
    switch (difficulty) {
      case 1:
        difficultyMultiplier = easyMultiplier;
        break;
      case 2:
        difficultyMultiplier = mediumMultiplier;
        break;
      case 3:
        difficultyMultiplier = hardMultiplier;
        break;
      default:
        difficultyMultiplier = mediumMultiplier;
    }

    double streakBonus =
        (streakCount * streakBonusPerDay).clamp(0.0, maxStreakBonus);

    return (baseXp * difficultyMultiplier * (1 + streakBonus)).round();
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
