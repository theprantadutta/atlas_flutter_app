import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/features/goals/providers/goals_provider.dart';
import 'package:atlas_flutter_app/features/goals/widgets/goal_card.dart';
import 'package:atlas_flutter_app/features/goals/widgets/goal_form_sheet.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_error_widget.dart';
import 'package:atlas_flutter_app/shared/widgets/loading_shimmer.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goalsState = ref.watch(goalsProvider);
    final filteredGoals = goalsState.filteredGoals;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Goals',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goals_fab',
        onPressed: () => showGoalFormSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(goalsProvider.notifier).loadGoals(),
        child: goalsState.isLoading
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LoadingShimmer.card(height: 140),
                  ),
                ),
              )
            : goalsState.error != null
                ? AppErrorDisplay(
                    message: goalsState.error!,
                    onRetry: () =>
                        ref.read(goalsProvider.notifier).loadGoals(),
                  )
                : CustomScrollView(
                    slivers: [
                      // Filter chips
                      SliverToBoxAdapter(
                        child: _buildFilterSection(
                          context,
                          ref,
                          goalsState,
                          isDark,
                        ),
                      ),

                      // Goal list or empty
                      if (filteredGoals.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(theme),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList.builder(
                            itemCount: filteredGoals.length,
                            itemBuilder: (context, index) {
                              return GoalCard(goal: filteredGoals[index]);
                            },
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    WidgetRef ref,
    GoalsState state,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: GoalFilter.values.map((filter) {
                final isSelected = state.activeFilter == filter;
                final label = switch (filter) {
                  GoalFilter.all => 'All',
                  GoalFilter.active => 'Active',
                  GoalFilter.completed => 'Completed',
                  GoalFilter.overdue => 'Overdue',
                  GoalFilter.dueSoon => 'Due Soon',
                };

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(goalsProvider.notifier).setFilter(filter),
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
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
          ),
          const SizedBox(height: 8),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: GoalCategory.values.map((cat) {
                final isSelected = state.selectedCategory == cat;
                final label = switch (cat) {
                  GoalCategory.career => 'Career',
                  GoalCategory.health => 'Health',
                  GoalCategory.education => 'Education',
                  GoalCategory.financial => 'Financial',
                  GoalCategory.personal => 'Personal',
                  GoalCategory.fitness => 'Fitness',
                  GoalCategory.social => 'Social',
                  GoalCategory.creativity => 'Creativity',
                };

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(goalsProvider.notifier).setCategory(cat),
                    selectedColor:
                        AppColors.secondary.withValues(alpha: 0.15),
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? AppColors.secondary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.secondary.withValues(alpha: 0.4)
                          : (isDark
                              ? AppColors.cardBorderDark
                              : AppColors.cardBorderLight),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_circle_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No goals found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set a goal to start your journey!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
