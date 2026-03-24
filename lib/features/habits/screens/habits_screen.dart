import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_error_widget.dart';
import 'package:atlas_flutter_app/shared/widgets/loading_shimmer.dart';

import 'package:atlas_flutter_app/features/habits/providers/habits_provider.dart';
import 'package:atlas_flutter_app/features/habits/widgets/habit_card.dart';
import 'package:atlas_flutter_app/features/habits/widgets/habit_form_sheet.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(habitsProvider);
    final notifier = ref.read(habitsProvider.notifier);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => notifier.loadHabits(),
        child: CustomScrollView(
          slivers: [
            // ─── App Bar ───
            SliverAppBar(
              floating: true,
              snap: true,
              title: Text(
                'Habits',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // ─── Body ───
            if (state.isLoading)
              _buildLoadingSliver()
            else if (state.error != null)
              SliverFillRemaining(
                child: AppErrorDisplay(
                  message: state.error!,
                  onRetry: () => notifier.loadHabits(),
                ),
              )
            else ...[
              // ─── Summary Card ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: _ProgressSummaryCard(
                    completed: notifier.todayCompletedCount,
                    total: notifier.todayTotalCount,
                    progress: notifier.todayProgress,
                    maxStreak: notifier.maxStreak,
                    isDark: isDark,
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(
                        begin: -0.05,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),
                ),
              ),

              // ─── Category Filter ───
              SliverToBoxAdapter(
                child: _CategoryFilterBar(
                  selectedCategory: state.selectedCategory,
                  onSelected: (cat) => notifier.setCategory(cat),
                  isDark: isDark,
                ),
              ),

              // ─── Grouped Habit Lists ───
              if (notifier.filteredHabits.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(theme),
                )
              else
                ..._buildGroupedSections(notifier, theme, isDark),

              // Bottom spacing for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ],
        ),
      ),

      // ─── FAB ───
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'habits_fab',
        onPressed: () => showHabitFormSheet(context, ref: ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Habit'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  List<Widget> _buildGroupedSections(
    HabitsNotifier notifier,
    ThemeData theme,
    bool isDark,
  ) {
    final grouped = notifier.habitsByFrequency;
    final slivers = <Widget>[];

    // Maintain order: Daily, Weekly, Custom
    for (final frequency in ['Daily', 'Weekly', 'Custom']) {
      final habits = grouped[frequency];
      if (habits == null || habits.isEmpty) continue;

      // Section header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Icon(
                  switch (frequency) {
                    'Daily' => Icons.today_rounded,
                    'Weekly' => Icons.date_range_rounded,
                    _ => Icons.tune_rounded,
                  },
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  frequency,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${habits.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Habit cards
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final habit = habits[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: HabitCard(habit: habit, isDark: isDark)
                    .animate()
                    .fadeIn(
                      delay: (index * 60).ms,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    )
                    .slideX(
                      begin: 0.06,
                      end: 0,
                      delay: (index * 60).ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
              );
            },
            childCount: habits.length,
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildLoadingSliver() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: LoadingShimmer.listItem(height: 80),
        ),
        childCount: 6,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.loop_rounded,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Build daily routines and watch\nyour streaks grow!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Progress Summary Card
// ═══════════════════════════════════════════════════════════════════

class _ProgressSummaryCard extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;
  final int maxStreak;
  final bool isDark;

  const _ProgressSummaryCard({
    required this.completed,
    required this.total,
    required this.progress,
    required this.maxStreak,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final gradient = AppColors.heroSecondaryGradient(isDark);
    final shadowColor = isDark ? AppColors.secondary : const Color(0xFF0EA5C9);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ─── Circular Progress ───
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$completed/$total',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // ─── Info ───
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Progress",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Add habits to get started'
                      : completed == total
                          ? 'All done! Great job!'
                          : '${total - completed} habits remaining',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // ─── Streak ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orangeAccent,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  '$maxStreak',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

// ═══════════════════════════════════════════════════════════════════
//  Category Filter Bar
// ═══════════════════════════════════════════════════════════════════

class _CategoryFilterBar extends StatelessWidget {
  final HabitCategory? selectedCategory;
  final ValueChanged<HabitCategory?> onSelected;
  final bool isDark;

  const _CategoryFilterBar({
    required this.selectedCategory,
    required this.onSelected,
    required this.isDark,
  });

  static const _categoryMeta = <(HabitCategory, String, Color)>[
    (HabitCategory.health, 'Health', AppColors.categoryHealth),
    (HabitCategory.fitness, 'Fitness', AppColors.categoryFitness),
    (HabitCategory.learning, 'Learning', AppColors.categoryLearning),
    (HabitCategory.mindfulness, 'Mindfulness', AppColors.categoryMindfulness),
    (HabitCategory.productivity, 'Productivity', AppColors.categoryWork),
    (HabitCategory.social, 'Social', AppColors.categorySocial),
    (HabitCategory.creativity, 'Creativity', AppColors.categoryCreative),
    (HabitCategory.personal, 'Personal', AppColors.info),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _HabitFilterChip(
            label: 'All',
            isSelected: selectedCategory == null,
            color: AppColors.secondary,
            isDark: isDark,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          ..._categoryMeta.map((meta) {
            final (cat, label, color) = meta;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _HabitFilterChip(
                label: label,
                isSelected: selectedCategory == cat,
                color: color,
                isDark: isDark,
                onTap: () =>
                    onSelected(selectedCategory == cat ? null : cat),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HabitFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _HabitFilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
