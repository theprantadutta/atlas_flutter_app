import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/core/utils/haptic_utils.dart';
import 'package:atlas_flutter_app/data/models/task.dart';
import 'package:atlas_flutter_app/shared/services/overlay_service.dart';

/// Handles the post-completion flow for tasks: XP overlay, haptics, level-up.
class TaskCompletionHandler {
  const TaskCompletionHandler();

  /// Process the completion response and show gamification overlays.
  ///
  /// [apiResponse] is the raw response from the complete-task endpoint.
  /// [completedTask] is the task that was just completed.
  /// [showXpOverlay] controls whether the XP gain overlay is shown
  /// (set to false when XP is shown inline on the card).
  void handleCompletion(
    Map<String, dynamic> apiResponse,
    Task completedTask, {
    bool showXpOverlay = true,
  }) {
    // Haptic success feedback
    HapticUtils.successVibrate();

    // Extract XP info from API response, fall back to task's own reward
    final xpGained =
        apiResponse['xp_gained'] as int? ?? completedTask.xpReward;
    final streakBonus = apiResponse['streak_bonus'] as int?;

    // Show XP gain overlay (unless suppressed for inline display)
    if (showXpOverlay) {
      OverlayService.showXpGain(
        xp: xpGained,
        streakBonus: streakBonus,
      );
    }

    // Check for level-up
    final newLevel = apiResponse['new_level'] as int?;
    final previousLevel = apiResponse['previous_level'] as int?;

    if (newLevel != null && previousLevel != null && newLevel > previousLevel) {
      // Delay so XP overlay shows first
      Future.delayed(const Duration(milliseconds: 2200), () {
        OverlayService.showLevelUp(newLevel: newLevel);
      });
    }

    // Check for unlocked achievements
    final achievements = apiResponse['achievements_unlocked'] as List?;
    if (achievements != null && achievements.isNotEmpty) {
      for (var i = 0; i < achievements.length; i++) {
        final achievement = achievements[i] as Map<String, dynamic>;
        Future.delayed(Duration(milliseconds: 2200 + (i + 1) * 2200), () {
          OverlayService.showAchievementUnlock(
            title: achievement['title'] as String? ?? 'Achievement Unlocked',
            tier: achievement['tier'] as String? ?? 'bronze',
          );
        });
      }
    }
  }

  /// Convenience: calculate estimated XP for preview purposes.
  static int estimateXp({
    required String taskType,
    required int difficulty,
    int streakCount = 0,
  }) {
    return GamificationConstants.calculateTaskXp(
      taskType: taskType,
      difficulty: difficulty,
      streakCount: streakCount,
    );
  }
}
