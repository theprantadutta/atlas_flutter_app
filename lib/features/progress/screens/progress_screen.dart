import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:atlas_flutter_app/features/progress/providers/progress_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_error_widget.dart';
import 'package:atlas_flutter_app/shared/widgets/loading_shimmer.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Progress',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(progressProvider.notifier).loadProgress(),
        child: state.isLoading
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LoadingShimmer.card(height: 80),
                  ),
                ),
              )
            : state.error != null
                ? AppErrorDisplay(
                    message: state.error!,
                    onRetry: () =>
                        ref.read(progressProvider.notifier).loadProgress(),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      // Date range selector
                      _buildDateRange(context, ref, state, isDark),
                      const SizedBox(height: 16),

                      // Summary cards
                      _buildSummary(context, state, isDark),
                      const SizedBox(height: 20),

                      // Daily entries header
                      Text(
                        'Daily Breakdown',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Entries list
                      if (state.entries.isEmpty)
                        _buildEmptyState(theme)
                      else
                        ...state.entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _DayEntryCard(
                                date: entry.date,
                                xpGained: entry.xpGained,
                                tasksCompleted: entry.tasksCompleted,
                                streakCount: entry.streakCount,
                                maxXp: state.entries
                                    .fold<int>(1, (m, e) =>
                                        e.xpGained > m ? e.xpGained : m),
                                isDark: isDark,
                              ),
                            )),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDateRange(
    BuildContext context,
    WidgetRef ref,
    ProgressState state,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    Future<void> pickDate(bool isStart) async {
      final now = DateTime.now();
      final initial = isStart ? state.startDate : state.endDate;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial ?? now,
        firstDate: now.subtract(const Duration(days: 365 * 2)),
        lastDate: now,
      );
      if (picked != null) {
        final start = isStart ? picked : (state.startDate ?? now);
        final end = isStart ? (state.endDate ?? now) : picked;
        ref.read(progressProvider.notifier).setDateRange(start, end);
      }
    }

    return Row(
      children: [
        Expanded(
          child: _DateChip(
            label: 'From',
            date: state.startDate,
            onTap: () => pickDate(true),
            isDark: isDark,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: _DateChip(
            label: 'To',
            date: state.endDate,
            onTap: () => pickDate(false),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context,
    ProgressState state,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total XP',
            value: '${state.totalXp}',
            icon: Icons.bolt_rounded,
            color: AppColors.xpPrimary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Tasks Done',
            value: '${state.totalTasksCompleted}',
            icon: Icons.check_circle_rounded,
            color: AppColors.info,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Avg XP/Day',
            value: state.avgXpPerDay.toStringAsFixed(0),
            icon: Icons.trending_up_rounded,
            color: AppColors.tertiary,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline_rounded,
              size: 64,
              color:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No progress data yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete tasks to see your progress here!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Private Helper Widgets
// ═══════════════════════════════════════════════════════════════════

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isDark;

  const _DateChip({
    required this.label,
    required this.date,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    date != null
                        ? DateFormat('MMM d, y').format(date!)
                        : 'Select',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayEntryCard extends StatelessWidget {
  final DateTime date;
  final int xpGained;
  final int tasksCompleted;
  final int streakCount;
  final int maxXp;
  final bool isDark;

  const _DayEntryCard({
    required this.date,
    required this.xpGained,
    required this.tasksCompleted,
    required this.streakCount,
    required this.maxXp,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Intensity: higher XP = more green tint
    final intensity = maxXp > 0 ? (xpGained / maxXp).clamp(0.0, 1.0) : 0.0;
    final bgColor = Color.lerp(
      isDark ? AppColors.cardDark : AppColors.cardLight,
      AppColors.xpPrimary.withValues(alpha: 0.15),
      intensity,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Row(
        children: [
          // Date column
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Text(
                  DateFormat('d').format(date),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Divider
          Container(
            width: 2,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.xpPrimary.withValues(alpha: 0.2 + intensity * 0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Row(
              children: [
                _DetailChip(
                  icon: Icons.bolt_rounded,
                  label: '+$xpGained XP',
                  color: AppColors.xpPrimary,
                ),
                const SizedBox(width: 12),
                _DetailChip(
                  icon: Icons.check_circle_outlined,
                  label: '$tasksCompleted tasks',
                  color: AppColors.info,
                ),
              ],
            ),
          ),

          // Streak
          if (streakCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.streakFlame.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 14,
                    color: AppColors.streakFlame,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$streakCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.streakFlame,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
