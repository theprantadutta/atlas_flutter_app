import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/utils/haptic_utils.dart';
import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/habit.dart';
import 'package:atlas_flutter_app/shared/services/overlay_service.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

import 'package:atlas_flutter_app/features/habits/providers/habits_provider.dart';
import 'package:atlas_flutter_app/features/habits/widgets/habit_form_sheet.dart';

class HabitCard extends ConsumerWidget {
  final Habit habit;
  final bool isDark;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catColor = _categoryColor(habit.category);

    return GestureDetector(
      onTap: () => showHabitFormSheet(context, ref: ref, habit: habit),
      onLongPress: () => _showDeleteConfirm(context, ref),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ─── Category Color Indicator ───
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
                  // Title + Frequency Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habit.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: habit.isCompletedToday
                                ? TextDecoration.lineThrough
                                : null,
                            color: habit.isCompletedToday
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FrequencyBadge(frequency: habit.frequency),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ─── Meta Row: Streak + Completion Rate ───
                  Row(
                    children: [
                      // Streak
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: habit.streakCount > 0
                            ? AppColors.streakFlame
                            : AppColors.streakFlame.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.streakCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: habit.streakCount > 0
                              ? AppColors.streakFlame
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Completion rate bar
                      Expanded(
                        child: _CompletionRateBar(
                          rate: habit.completionRate,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(habit.completionRate * 100).round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // ─── Toggle Button ───
            _CompletionToggle(
              isCompleted: habit.isCompletedToday,
              onToggle: () => _handleComplete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleComplete(BuildContext context, WidgetRef ref) async {
    if (habit.isCompletedToday) return; // Already completed

    HapticUtils.successVibrate();
    final response =
        await ref.read(habitsProvider.notifier).completeHabit(habit.id);

    if (response != null) {
      final xpGained = response['xp_gained'] as int? ?? 15;
      final streakBonus = response['streak_bonus'] as int?;

      OverlayService.showXpGain(xp: xpGained, streakBonus: streakBonus);

      // Check for level-up
      final newLevel = response['new_level'] as int?;
      final previousLevel = response['previous_level'] as int?;
      if (newLevel != null &&
          previousLevel != null &&
          newLevel > previousLevel) {
        Future.delayed(const Duration(milliseconds: 2200), () {
          OverlayService.showLevelUp(newLevel: newLevel);
        });
      }
    }
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    HapticUtils.mediumTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Delete "${habit.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(habitsProvider.notifier).deleteHabit(habit.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(HabitCategory category) {
    return switch (category) {
      HabitCategory.health => AppColors.categoryHealth,
      HabitCategory.fitness => AppColors.categoryFitness,
      HabitCategory.mindfulness => AppColors.categoryMindfulness,
      HabitCategory.productivity => AppColors.categoryWork,
      HabitCategory.learning => AppColors.categoryLearning,
      HabitCategory.social => AppColors.categorySocial,
      HabitCategory.creative => AppColors.categoryCreative,
      HabitCategory.custom => AppColors.info,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Frequency Badge
// ═══════════════════════════════════════════════════════════════════

class _FrequencyBadge extends StatelessWidget {
  final HabitFrequency frequency;

  const _FrequencyBadge({required this.frequency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (frequency) {
      HabitFrequency.daily => ('Daily', AppColors.secondary),
      HabitFrequency.weekly => ('Weekly', AppColors.badgeEpic),
      HabitFrequency.weekdays => ('Weekdays', AppColors.info),
      HabitFrequency.weekends => ('Weekends', AppColors.warning),
      HabitFrequency.custom => ('Custom', AppColors.tertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Completion Rate Bar
// ═══════════════════════════════════════════════════════════════════

class _CompletionRateBar extends StatelessWidget {
  final double rate;
  final bool isDark;

  const _CompletionRateBar({required this.rate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: rate.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: AppColors.xpPrimary.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation(
          rate >= 0.8 ? AppColors.xpPrimary : AppColors.secondary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Completion Toggle
// ═══════════════════════════════════════════════════════════════════

class _CompletionToggle extends StatefulWidget {
  final bool isCompleted;
  final VoidCallback onToggle;

  const _CompletionToggle({
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  State<_CompletionToggle> createState() => _CompletionToggleState();
}

class _CompletionToggleState extends State<_CompletionToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.isCompleted) return;
    _controller.forward().then((_) => _controller.reverse());
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isCompleted
                ? AppColors.xpPrimary
                : Colors.transparent,
            border: Border.all(
              color: widget.isCompleted
                  ? AppColors.xpPrimary
                  : AppColors.secondary,
              width: 2,
            ),
          ),
          child: widget.isCompleted
              ? const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
