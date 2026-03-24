import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/goal.dart';
import 'package:atlas_flutter_app/features/goals/providers/goals_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

class GoalCard extends ConsumerStatefulWidget {
  final Goal goal;

  const GoalCard({super.key, required this.goal});

  @override
  ConsumerState<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<GoalCard> {
  bool _isExpanded = false;
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.goal.progress;
  }

  @override
  void didUpdateWidget(GoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal.progress != widget.goal.progress) {
      _sliderValue = widget.goal.progress;
    }
  }

  Color get _priorityColor => switch (widget.goal.priority) {
        GoalPriority.low => AppColors.info,
        GoalPriority.medium => AppColors.warning,
        GoalPriority.high => AppColors.tertiary,
        GoalPriority.critical => AppColors.error,
      };

  Color _statusColor(GoalStatus status) => switch (status) {
        GoalStatus.notStarted => AppColors.textSecondaryLight,
        GoalStatus.inProgress => AppColors.info,
        GoalStatus.completed => AppColors.success,
        GoalStatus.onHold => AppColors.warning,
        GoalStatus.cancelled => AppColors.error,
      };

  String _statusLabel(GoalStatus status) => switch (status) {
        GoalStatus.notStarted => 'Not Started',
        GoalStatus.inProgress => 'In Progress',
        GoalStatus.completed => 'Completed',
        GoalStatus.onHold => 'On Hold',
        GoalStatus.cancelled => 'Cancelled',
      };

  String _categoryLabel(GoalCategory cat) => switch (cat) {
        GoalCategory.health => 'Health',
        GoalCategory.fitness => 'Fitness',
        GoalCategory.mindfulness => 'Mindfulness',
        GoalCategory.learning => 'Learning',
        GoalCategory.career => 'Career',
        GoalCategory.financial => 'Financial',
        GoalCategory.relationships => 'Relationships',
        GoalCategory.personal => 'Personal',
        GoalCategory.custom => 'Custom',
      };

  bool get _isOverdue =>
      widget.goal.deadline != null &&
      widget.goal.deadline!.isBefore(DateTime.now()) &&
      widget.goal.status != GoalStatus.completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goal = widget.goal;
    final progressPercent = (goal.progress * 100).round();

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Priority color bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: _priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Chips row
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Chip(
                            label: _categoryLabel(goal.category),
                            color: theme.colorScheme.primary,
                          ),
                          _Chip(
                            label: _statusLabel(goal.status),
                            color: _statusColor(goal.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: goal.progress.clamp(0.0, 1.0),
                                backgroundColor:
                                    AppColors.xpPrimary.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation(
                                  goal.status == GoalStatus.completed
                                      ? AppColors.success
                                      : AppColors.xpPrimary,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$progressPercent%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.xpPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Deadline + XP row
                      Row(
                        children: [
                          if (goal.deadline != null) ...[
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: _isOverdue
                                  ? AppColors.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, y').format(goal.deadline!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _isOverdue
                                    ? AppColors.error
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight:
                                    _isOverdue ? FontWeight.w700 : null,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.xpPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${(goal.progress * 100).round()} XP',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.xpPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Expandable section
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: _buildExpandedContent(theme),
                        crossFadeState: _isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 250),
                        sizeCurve: Curves.easeInOut,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    final goal = widget.goal;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            Text(
              goal.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
          ],
          // Progress slider
          Text(
            'Update Progress',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.xpPrimary,
                    inactiveTrackColor:
                        AppColors.xpPrimary.withValues(alpha: 0.15),
                    thumbColor: AppColors.xpPrimary,
                    overlayColor: AppColors.xpPrimary.withValues(alpha: 0.12),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _sliderValue.clamp(0.0, 1.0),
                    onChanged: (v) => setState(() => _sliderValue = v),
                    onChangeEnd: (v) {
                      ref
                          .read(goalsProvider.notifier)
                          .updateProgress(goal.id, v);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${(_sliderValue * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.xpPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
