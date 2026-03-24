import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/features/achievements/providers/achievements_provider.dart';
import 'package:atlas_flutter_app/features/achievements/widgets/achievement_card.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_card.dart';
import 'package:atlas_flutter_app/shared/widgets/app_error_widget.dart';
import 'package:atlas_flutter_app/shared/widgets/loading_shimmer.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              state.isGridView
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
            ),
            tooltip: state.isGridView ? 'List view' : 'Grid view',
            onPressed: () =>
                ref.read(achievementsProvider.notifier).toggleViewMode(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(achievementsProvider.notifier).loadAchievements(),
        child: state.isLoading
            ? _buildLoading()
            : state.error != null
                ? AppErrorDisplay(
                    message: state.error!,
                    onRetry: () => ref
                        .read(achievementsProvider.notifier)
                        .loadAchievements(),
                  )
                : CustomScrollView(
                    slivers: [
                      // Summary card
                      SliverToBoxAdapter(
                        child: _buildSummary(context, state, isDark),
                      ),

                      // Filters
                      SliverToBoxAdapter(
                        child: _buildFilters(context, ref, state, isDark),
                      ),

                      // Grid or List
                      if (state.filteredAchievements.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(theme),
                        )
                      else if (state.isGridView)
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          sliver: SliverGrid.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                            itemCount: state.filteredAchievements.length,
                            itemBuilder: (context, index) {
                              return AchievementCard(
                                achievement:
                                    state.filteredAchievements[index],
                              );
                            },
                          ),
                        )
                      else
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          sliver: SliverList.builder(
                            itemCount: state.filteredAchievements.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AchievementCard(
                                  achievement:
                                      state.filteredAchievements[index],
                                  isCompact: true,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LoadingShimmer.card(height: 100),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => LoadingShimmer.card(height: 200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    AchievementsState state,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final unlocked = state.unlockedCount;
    final total = state.totalCount;
    final progress = total > 0 ? unlocked / total : 0.0;
    final tiers = state.tierBreakdown;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: AppCard(
        showGradientBorder: true,
        gradientBorderColors: const [AppColors.tertiary, AppColors.xpPrimary],
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.tertiary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unlocked / $total Unlocked',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor:
                              AppColors.tertiary.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.tertiary),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tier breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TierBadge(
                    label: 'Bronze',
                    count: tiers['bronze'] ?? 0,
                    color: GamificationConstants.bronzeColor),
                _TierBadge(
                    label: 'Common',
                    count: tiers['common'] ?? 0,
                    color: GamificationConstants.commonColor),
                _TierBadge(
                    label: 'Rare',
                    count: tiers['rare'] ?? 0,
                    color: GamificationConstants.rareColor),
                _TierBadge(
                    label: 'Epic',
                    count: tiers['epic'] ?? 0,
                    color: GamificationConstants.epicColor),
                _TierBadge(
                    label: 'Legendary',
                    count: tiers['legendary'] ?? 0,
                    color: GamificationConstants.legendaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    WidgetRef ref,
    AchievementsState state,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AchievementType.values.map((type) {
                final isSelected = state.typeFilter == type;
                final label = switch (type) {
                  AchievementType.streak => 'Streaks',
                  AchievementType.total => 'Total',
                  AchievementType.milestone => 'Milestones',
                  AchievementType.category => 'Category',
                  AchievementType.level => 'Levels',
                  AchievementType.special => 'Special',
                };

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => ref
                        .read(achievementsProvider.notifier)
                        .setTypeFilter(type),
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
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
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Unlock status toggle
          Row(
            children: [
              _StatusToggle(
                label: 'All',
                isSelected: state.unlockedFilter == null,
                onTap: () => ref
                    .read(achievementsProvider.notifier)
                    .setUnlockedFilter(null),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _StatusToggle(
                label: 'Unlocked',
                isSelected: state.unlockedFilter == true,
                onTap: () => ref
                    .read(achievementsProvider.notifier)
                    .setUnlockedFilter(true),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _StatusToggle(
                label: 'Locked',
                isSelected: state.unlockedFilter == false,
                onTap: () => ref
                    .read(achievementsProvider.notifier)
                    .setUnlockedFilter(false),
                isDark: isDark,
              ),
            ],
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
            Icons.emoji_events_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No achievements found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep completing tasks to earn badges!',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TierBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _StatusToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary.withValues(alpha: 0.4)
                : (isDark
                    ? AppColors.cardBorderDark
                    : AppColors.cardBorderLight),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? AppColors.secondary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
