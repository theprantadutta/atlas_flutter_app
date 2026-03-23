import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/data/models/achievement.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isCompact;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.isCompact = false,
  });

  Color get _tierColor =>
      GamificationConstants.colorForBadgeTier(achievement.badgeTier);

  IconData get _typeIcon => switch (achievement.achievementType.name) {
        'taskCompletion' => Icons.check_circle_rounded,
        'streak' => Icons.local_fire_department_rounded,
        'levelUp' => Icons.arrow_upward_rounded,
        'habitMastery' => Icons.loop_rounded,
        'goalCompletion' => Icons.flag_rounded,
        'exploration' => Icons.explore_rounded,
        'social' => Icons.people_rounded,
        'special' => Icons.auto_awesome_rounded,
        _ => Icons.emoji_events_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: achievement.isUnlocked
                ? _tierColor.withValues(alpha: 0.5)
                : (isDark
                    ? AppColors.cardBorderDark
                    : AppColors.cardBorderLight),
            width: achievement.isUnlocked ? 1.5 : 1,
          ),
          boxShadow: achievement.isUnlocked
              ? [
                  BoxShadow(
                    color: _tierColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge icon
                  Container(
                    width: isCompact ? 44 : 52,
                    height: isCompact ? 44 : 52,
                    decoration: BoxDecoration(
                      color: achievement.isUnlocked
                          ? _tierColor.withValues(alpha: 0.15)
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _typeIcon,
                      size: isCompact ? 22 : 26,
                      color: achievement.isUnlocked
                          ? _tierColor
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    achievement.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: achievement.isUnlocked
                          ? null
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  if (achievement.description != null)
                    Text(
                      achievement.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: achievement.isUnlocked
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.progress.clamp(0.0, 1.0),
                      backgroundColor: _tierColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(
                        achievement.isUnlocked
                            ? _tierColor
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                      ),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tier chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _tierColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      achievement.badgeTier[0].toUpperCase() +
                          achievement.badgeTier.substring(1),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _tierColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Locked overlay
            if (!achievement.isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _tierColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_typeIcon, size: 36, color: _tierColor),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                achievement.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              if (achievement.description != null)
                Text(
                  achievement.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),

              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(achievement.progress * 100).round()}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _tierColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Progress',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: achievement.progress.clamp(0.0, 1.0),
                  backgroundColor: _tierColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(_tierColor),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 16),

              // Status & date
              if (achievement.isUnlocked && achievement.unlockedAt != null)
                Text(
                  'Unlocked on ${DateFormat('MMMM d, y').format(achievement.unlockedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
