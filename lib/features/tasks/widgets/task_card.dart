import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:atlas_flutter_app/core/utils/haptic_utils.dart';
import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/task.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

import 'package:atlas_flutter_app/features/tasks/providers/task_completion_handler.dart';
import 'package:atlas_flutter_app/features/tasks/providers/tasks_provider.dart';
import 'package:atlas_flutter_app/features/tasks/widgets/task_form_sheet.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final bool isDark;

  const TaskCard({
    super.key,
    required this.task,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catColor = _categoryColor(task.category);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
          size: 28,
        ),
      ),
      confirmDismiss: (_) async {
        HapticUtils.mediumTap();
        return await _showDeleteConfirm(context);
      },
      onDismissed: (_) {
        ref.read(tasksProvider.notifier).deleteTask(task.id);
      },
      child: GestureDetector(
        onTap: () => showTaskFormSheet(context, ref: ref, task: task),
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
                    // Title
                    Text(
                      task.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Description
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // ─── Meta Row: XP, Difficulty, Due Date ───
                    Row(
                      children: [
                        // XP badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.xpPrimary.withValues(alpha: 0.12),
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
                        const SizedBox(width: 8),

                        // Difficulty dots
                        _DifficultyIndicator(difficulty: task.difficulty),

                        const Spacer(),

                        // Due date
                        if (task.dueDate != null) _DueDateLabel(task: task),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ─── Completion Checkbox ───
              _CompletionCheckbox(
                task: task,
                onComplete: () => _handleComplete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleComplete(BuildContext context, WidgetRef ref) async {
    HapticUtils.successVibrate();
    final response =
        await ref.read(tasksProvider.notifier).completeTask(task.id);
    if (response != null) {
      const handler = TaskCompletionHandler();
      handler.handleCompletion(response, task);
    }
  }

  Future<bool> _showDeleteConfirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Delete "${task.title}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
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

// ═══════════════════════════════════════════════════════════════════
//  Difficulty Indicator
// ═══════════════════════════════════════════════════════════════════

class _DifficultyIndicator extends StatelessWidget {
  final int difficulty;

  const _DifficultyIndicator({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    // Map 1-10 difficulty to 1-3 stars
    final stars = difficulty <= 3 ? 1 : (difficulty <= 6 ? 2 : 3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final active = i < stars;
        return Icon(
          active ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: active
              ? AppColors.tertiary
              : AppColors.tertiary.withValues(alpha: 0.25),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Due Date Label
// ═══════════════════════════════════════════════════════════════════

class _DueDateLabel extends StatelessWidget {
  final Task task;

  const _DueDateLabel({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = task.isOverdue;
    final isToday = task.isDueToday;
    final color = isOverdue
        ? AppColors.error
        : isToday
            ? AppColors.warning
            : theme.colorScheme.onSurfaceVariant;

    final dateStr = isToday
        ? 'Today'
        : isOverdue
            ? 'Overdue'
            : DateFormat('MMM d').format(task.dueDate!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          dateStr,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Completion Checkbox
// ═══════════════════════════════════════════════════════════════════

class _CompletionCheckbox extends StatefulWidget {
  final Task task;
  final VoidCallback onComplete;

  const _CompletionCheckbox({
    required this.task,
    required this.onComplete,
  });

  @override
  State<_CompletionCheckbox> createState() => _CompletionCheckboxState();
}

class _CompletionCheckboxState extends State<_CompletionCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    _controller.forward().then((_) => _controller.reverse());
    widget.onComplete();
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
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _isCompleting ? AppColors.xpPrimary : AppColors.primary,
              width: 2,
            ),
            color: _isCompleting
                ? AppColors.xpPrimary.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          child: _isCompleting
              ? const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.xpPrimary,
                )
              : null,
        ),
      ),
    );
  }
}
