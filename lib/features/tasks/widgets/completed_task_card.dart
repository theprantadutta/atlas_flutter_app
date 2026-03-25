import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/task.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// A simplified, read-only card for completed tasks.
class CompletedTaskCard extends StatelessWidget {
  final Task task;
  final bool isDark;

  const CompletedTaskCard({
    super.key,
    required this.task,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _categoryColor(task.category).withValues(alpha: 0.4);

    return Opacity(
      opacity: 0.65,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.cardBorderDark
                : AppColors.cardBorderLight,
          ),
        ),
        child: Row(
          children: [
            // ─── Desaturated Category Color Strip ───
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: catColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // ─── Content ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with strikethrough
                  Text(
                    task.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: theme.colorScheme.onSurfaceVariant,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description (muted)
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // ─── XP Badge ───
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.xpPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${task.xpReward} XP',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.xpPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // ─── Golden Checkmark ───
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.xpPrimary.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.xpPrimary,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.xpPrimary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Color _categoryColor(TaskCategory category) {
    return switch (category) {
      TaskCategory.health => AppColors.categoryHealth,
      TaskCategory.fitness => AppColors.categoryFitness,
      TaskCategory.mindfulness => AppColors.categoryMindfulness,
      TaskCategory.work => AppColors.categoryWork,
      TaskCategory.learning => AppColors.categoryLearning,
      TaskCategory.social => AppColors.categorySocial,
      TaskCategory.creative => AppColors.categoryCreative,
      TaskCategory.finance => AppColors.tertiary,
      TaskCategory.custom => AppColors.info,
    };
  }
}
