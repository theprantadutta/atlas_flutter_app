import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:atlas_flutter_app/core/utils/haptic_utils.dart';
import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/task.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

import 'package:atlas_flutter_app/features/tasks/providers/task_completion_handler.dart';
import 'package:atlas_flutter_app/features/tasks/providers/tasks_provider.dart';
import 'package:atlas_flutter_app/features/tasks/widgets/task_form_sheet.dart';

class TaskCard extends ConsumerStatefulWidget {
  final Task task;
  final bool isDark;

  const TaskCard({
    super.key,
    required this.task,
    required this.isDark,
  });

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard>
    with TickerProviderStateMixin {
  bool _isRecentlyCompleted = false;
  int? _xpGained;

  late final AnimationController _slideOutController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _slideOutController,
      curve: Curves.easeInBack,
    ));
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideOutController,
      curve: Curves.easeIn,
    ));

    _slideOutController.addStatusListener(_onSlideOutComplete);
  }

  void _onSlideOutComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      // Card has fully slid out — no further action needed.
      // The provider already marked it completed; the screen will
      // move it to the completed section on next rebuild.
    }
  }

  @override
  void dispose() {
    _slideOutController.removeStatusListener(_onSlideOutComplete);
    _slideOutController.dispose();
    super.dispose();
  }

  void _handleComplete() async {
    HapticUtils.successVibrate();
    setState(() => _isRecentlyCompleted = true);

    final response =
        await ref.read(tasksProvider.notifier).completeTask(widget.task.id);

    if (response != null && mounted) {
      final xp = response['xp_reward'] as int? ??
          response['xp_gained'] as int? ??
          widget.task.xpReward;
      setState(() => _xpGained = xp);

      // Handle level-up/achievements but skip XP overlay (shown inline on card)
      const handler = TaskCompletionHandler();
      handler.handleCompletion(response, widget.task, showXpOverlay: false);
    }

    // Slide out after delay
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        _slideOutController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildCardContent(theme, widget.isDark),
      ),
    );
  }

  Widget _buildCardContent(ThemeData theme, bool isDark) {
    final catColor = _isRecentlyCompleted
        ? AppColors.xpPrimary
        : _categoryColor(widget.task.category);

    return Dismissible(
      key: ValueKey(widget.task.id),
      direction:
          _isRecentlyCompleted ? DismissDirection.none : DismissDirection.endToStart,
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
        ref.read(tasksProvider.notifier).deleteTask(widget.task.id);
      },
      child: GestureDetector(
        onTap: _isRecentlyCompleted
            ? null
            : () => showTaskFormSheet(context, ref: ref, task: widget.task),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isRecentlyCompleted
                  ? AppColors.xpPrimary.withValues(alpha: 0.3)
                  : isDark
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
                      widget.task.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: _isRecentlyCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor:
                            theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Description
                    if (widget.task.description != null &&
                        widget.task.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.task.description!,
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
                        _isRecentlyCompleted && _xpGained != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.xpPrimary
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+$_xpGained XP',
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.xpPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                                  .animate()
                                  .shimmer(
                                    duration: 1.seconds,
                                    color: AppColors.xpSecondary
                                        .withValues(alpha: 0.5),
                                  )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.xpPrimary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${widget.task.xpReward} XP',
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.xpPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                        const SizedBox(width: 8),

                        // Difficulty dots
                        _DifficultyIndicator(
                            difficulty: widget.task.difficulty),

                        const Spacer(),

                        // Due date
                        if (widget.task.dueDate != null)
                          _DueDateLabel(task: widget.task),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ─── Completion Checkbox ───
              _CompletionCheckbox(
                task: widget.task,
                onComplete: _handleComplete,
                isCompleted: _isRecentlyCompleted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Task'),
            content:
                Text('Delete "${widget.task.title}"? This cannot be undone.'),
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
  final bool isCompleted;

  const _CompletionCheckbox({
    required this.task,
    required this.onComplete,
    this.isCompleted = false,
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
    _isCompleting = widget.isCompleted;
  }

  @override
  void didUpdateWidget(covariant _CompletionCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _isCompleting = true;
    }
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
