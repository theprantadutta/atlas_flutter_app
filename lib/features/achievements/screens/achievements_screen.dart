import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/sample/sample_world.dart'
    show SampleAchievement, Tier, TierVisuals;
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/achievements/providers/achievement_providers.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// The Achievements sub-page — a calm, rewarding gallery of earned and
/// in-progress badges. Reads the local-first Drift gallery; local filter state
/// keeps it self-contained.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

enum _Filter { all, unlocked, locked }

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsStreamProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: achievementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Could not load your achievements')),
          data: (rows) {
            final all = rows.map(_toView).toList();
            final unlockedCount = all.where((a) => a.unlocked).length;
            final total = all.length;

            final visible = switch (_filter) {
              _Filter.all => all,
              _Filter.unlocked => all.where((a) => a.unlocked).toList(),
              _Filter.locked => all.where((a) => !a.unlocked).toList(),
            };

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.bottomNavSpace,
              ),
              children: [
                AtlasHeader(
                  title: 'Achievements',
                  subtitle: '$unlockedCount of $total earned',
                  onBack: () => context.pop(),
                ),
                AppSpacing.gapLg,
                _SummaryCard(unlockedCount: unlockedCount, total: total),
                AppSpacing.gapLg,
                Row(
                  children: [
                    CategoryChip(
                      label: 'All',
                      selected: _filter == _Filter.all,
                      onTap: () => setState(() => _filter = _Filter.all),
                    ),
                    AppSpacing.hGapSm,
                    CategoryChip(
                      label: 'Unlocked',
                      selected: _filter == _Filter.unlocked,
                      onTap: () => setState(() => _filter = _Filter.unlocked),
                    ),
                    AppSpacing.hGapSm,
                    CategoryChip(
                      label: 'Locked',
                      selected: _filter == _Filter.locked,
                      onTap: () => setState(() => _filter = _Filter.locked),
                    ),
                  ],
                ),
                AppSpacing.gapLg,
                if (visible.isEmpty)
                  const AtlasEmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'Nothing here yet',
                    message: 'Keep tending your habits and badges will bloom.',
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visible.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      // A touch taller so a 2-line description plus the locked
                      // progress bar never overflows the cell.
                      childAspectRatio: 0.76,
                    ),
                    itemBuilder: (context, index) {
                      return _AchievementTile(achievement: visible[index])
                          .animate()
                          .fadeIn(
                            delay: (AppMotion.fast * 0.25) * index,
                            duration: AppMotion.medium,
                          )
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            duration: AppMotion.medium,
                            curve: AppMotion.standard,
                          );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Map a Drift achievement row to the gallery view model. Tier is derived
/// from type + target (same formula as the backend) and the icon from the
/// stored icon key.
SampleAchievement _toView(Achievement row) {
  final target = achievementTargetFromCriteria(row.criteria);
  final tierName = achievementBadgeTier(row.achievementType, target);
  return SampleAchievement(
    id: row.id,
    title: row.title,
    desc: row.description ?? '',
    icon: _iconFor(row.iconPath),
    tier: _tierFrom(tierName),
    unlocked: row.isUnlocked,
    progress: row.progress,
  );
}

Tier _tierFrom(String name) {
  for (final t in Tier.values) {
    if (t.name == name) return t;
  }
  return Tier.bronze;
}

IconData _iconFor(String? key) => switch (key) {
      'wb_twilight' => Icons.wb_twilight_rounded,
      'task_alt' => Icons.task_alt_rounded,
      'self_improvement' => Icons.self_improvement_rounded,
      'water_drop' => Icons.water_drop_rounded,
      'auto_awesome' => Icons.auto_awesome_rounded,
      'public' => Icons.public_rounded,
      'forest' => Icons.forest_rounded,
      'menu_book' => Icons.menu_book_rounded,
      _ => Icons.emoji_events_rounded,
    };

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.unlockedCount, required this.total});

  final int unlockedCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : unlockedCount / total;

    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          ProgressRing(
            progress: progress,
            size: 76,
            child: Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppSpacing.hGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlockedCount unlocked',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Keep going — every ritual brings the next badge closer.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
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

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final SampleAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = achievement.tier;
    final unlocked = achievement.unlocked;

    return Opacity(
      opacity: unlocked ? 1 : 0.7,
      child: AtlasCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? tier.color.withValues(alpha: 0.18)
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    unlocked ? achievement.icon : Icons.lock_outline,
                    color: unlocked
                        ? tier.color
                        : theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                if (unlocked)
                  _TierChip(label: tier.label, color: tier.color),
              ],
            ),
            AppSpacing.gapMd,
            Text(
              achievement.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              achievement.desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const Spacer(),
            if (!unlocked) ...[
              AppSpacing.gapSm,
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.hGapXs,
                  Text(
                    '${(achievement.progress * 100).round()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AtlasProgressBar(
                fraction: achievement.progress,
                height: 7,
                color: tier.color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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
