import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/analytics/providers/analytics_provider.dart';
import 'package:atlas_flutter_app/features/analytics/widgets/chart_widgets.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_card.dart';
import 'package:atlas_flutter_app/shared/widgets/app_error_widget.dart';
import 'package:atlas_flutter_app/shared/widgets/loading_shimmer.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(analyticsProvider.notifier).loadAnalytics(),
        child: state.isLoading
            ? _buildLoading()
            : state.error != null
                ? AppErrorDisplay(
                    message: state.error!,
                    onRetry: () => ref
                        .read(analyticsProvider.notifier)
                        .loadAnalytics(),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      // Period selector
                      _buildPeriodSelector(context, ref, state, isDark),
                      const SizedBox(height: 16),

                      // Stat cards grid
                      _buildStatCards(context, state, isDark),
                      const SizedBox(height: 20),

                      // XP Trend chart
                      AppCard(
                        header: 'XP Trend',
                        child: XpTrendChart(data: state.data?.xpTrend),
                      ),
                      const SizedBox(height: 16),

                      // Completion chart
                      AppCard(
                        header: 'Task Completion',
                        child: CompletionBarChart(
                          data: state.data?.completionTrend,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category breakdown
                      AppCard(
                        header: 'Category Breakdown',
                        child: CategoryPieChart(
                          data: state.data?.categoryXpBreakdown,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Insights
                      _buildInsights(context, state, isDark),
                    ],
                  ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LoadingShimmer.card(height: 120),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    WidgetRef ref,
    AnalyticsState state,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AnalyticsPeriod.values.map((period) {
          final isSelected = state.period == period;
          final label = switch (period) {
            AnalyticsPeriod.week => 'This Week',
            AnalyticsPeriod.month => 'This Month',
            AnalyticsPeriod.allTime => 'All Time',
          };

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) =>
                  ref.read(analyticsProvider.notifier).setPeriod(period),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : (isDark
                        ? AppColors.cardBorderDark
                        : AppColors.cardBorderLight),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCards(
    BuildContext context,
    AnalyticsState state,
    bool isDark,
  ) {
    final data = state.data;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          label: 'Total XP',
          value: '${data?.totalXp ?? 0}',
          icon: Icons.bolt_rounded,
          iconColor: AppColors.xpPrimary,
          isDark: isDark,
        ),
        _StatCard(
          label: 'Tasks Done',
          value: '${data?.totalTasksCompleted ?? 0}',
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.info,
          isDark: isDark,
        ),
        _StatCard(
          label: 'Streak',
          value: '${data?.currentStreak ?? 0}',
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.streakFlame,
          isDark: isDark,
        ),
        _StatCard(
          label: 'Level',
          value: '${data?.currentLevel ?? 1}',
          icon: Icons.shield_rounded,
          iconColor: AppColors.tertiary,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildInsights(
    BuildContext context,
    AnalyticsState state,
    bool isDark,
  ) {
    final data = state.data;

    return AppCard(
      header: 'Insights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InsightRow(
            icon: Icons.trending_up_rounded,
            color: AppColors.xpPrimary,
            text:
                'Average ${data?.avgXpPerDay.toStringAsFixed(0) ?? '0'} XP per day',
          ),
          const SizedBox(height: 10),
          _InsightRow(
            icon: Icons.local_fire_department_rounded,
            color: AppColors.streakFlame,
            text:
                'Longest streak: ${data?.longestStreak ?? 0} days',
          ),
          const SizedBox(height: 10),
          _InsightRow(
            icon: Icons.today_rounded,
            color: AppColors.info,
            text:
                'Today: ${data?.todayXp ?? 0} XP earned, ${data?.todayTasks ?? 0} tasks',
          ),
          const SizedBox(height: 10),
          _InsightRow(
            icon: Icons.calendar_month_rounded,
            color: AppColors.secondary,
            text:
                'This week: ${data?.weekXp ?? 0} XP earned',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InsightRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
