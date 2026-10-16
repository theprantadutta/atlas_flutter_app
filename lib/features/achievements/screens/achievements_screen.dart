import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';
import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/achievements/providers/achievement_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Achievements: a gallery of badges. Earned ones wear their tier's color;
/// the ones still ahead are outlines with a quiet progress line.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  int _filter = 0; // 0 all, 1 earned, 2 to earn

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(achievementsStreamProvider);
    final rows = async.value ?? const <Achievement>[];
    final badges = rows.map(AchievementBadge.from).toList()
      ..sort((a, b) {
        if (a.unlocked != b.unlocked) return a.unlocked ? -1 : 1;
        if (!a.unlocked) return b.progress.compareTo(a.progress); // closest first
        return (b.unlockedAt ?? DateTime(0)).compareTo(a.unlockedAt ?? DateTime(0));
      });
    final earned = badges.where((b) => b.unlocked).length;
    final visible = switch (_filter) {
      1 => badges.where((b) => b.unlocked).toList(),
      2 => badges.where((b) => !b.unlocked).toList(),
      _ => badges,
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: readableInsets(context, top: AppSpacing.xs, bottom: AppSpacing.xxl),
          children: [
            ScreenHeader(
              title: 'Achievements',
              subtitle: badges.isEmpty ? null : '$earned of ${badges.length} earned',
              onBack: () => context.pop(),
            ),
            const SizedBox(height: AppSpacing.md),
            if (async.isLoading && rows.isEmpty) ...[
              const Skeleton(height: 150, radius: AppSpacing.radiusTile),
              const SizedBox(height: AppSpacing.md),
              const SkeletonList(count: 3, height: 120),
            ] else if (badges.isEmpty)
              const EmptyState(title: 'Badges are on their way.')
            else ...[
              _Summary(badges: badges, earned: earned),
              const SizedBox(height: AppSpacing.md),
              SegmentedPill(
                labels: const ['All', 'Earned', 'To earn'],
                index: _filter,
                onChanged: (i) => setState(() => _filter = i),
              ),
              const SizedBox(height: AppSpacing.md),
              if (visible.isEmpty)
                EmptyState(
                  title: _filter == 1 ? 'Your first badge is close.' : 'You’ve earned them all.',
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                )
              else
                LayoutBuilder(builder: (context, c) {
                  final w = (c.maxWidth - 16) / 3;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < visible.length; i++)
                        SizedBox(
                          width: w,
                          child: EntryFade(
                            id: 'badge-${visible[i].id}',
                            index: i,
                            child: _BadgeTile(
                              badge: visible[i],
                              onTap: () => _showBadge(context, visible[i]),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

/// A row from Drift, ready for the gallery.
class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tier,
    required this.unlocked,
    required this.progress,
    required this.target,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String tier;
  final bool unlocked;
  final double progress;
  final double target;
  final DateTime? unlockedAt;

  factory AchievementBadge.from(Achievement a) {
    final target = achievementTargetFromCriteria(a.criteria);
    return AchievementBadge(
      id: a.id,
      title: a.title,
      description: a.description ?? '',
      icon: _iconFor(a.iconPath),
      tier: achievementBadgeTier(a.achievementType, target),
      unlocked: a.isUnlocked,
      progress: a.isUnlocked ? 1 : a.progress.clamp(0.0, 1.0),
      target: target,
      unlockedAt: a.unlockedAt,
    );
  }

  String get tierLabel => tier[0].toUpperCase() + tier.substring(1);

  /// Tier colors, from the category palette: bronze is amber, common sky,
  /// rare violet, epic coral; legendary wears the sunrise.
  Color get tierColor => switch (tier) {
        'common' => AppColors.sky,
        'rare' => AppColors.violet,
        'epic' => AppColors.coral,
        'legendary' => AppColors.sunriseB,
        _ => AppColors.amber,
      };
}

IconData _iconFor(String? key) => switch (key) {
      'wb_twilight' => Symbols.wb_twilight_rounded,
      'task_alt' => Symbols.task_alt_rounded,
      'self_improvement' => Symbols.self_improvement_rounded,
      'water_drop' => Symbols.water_drop_rounded,
      'auto_awesome' => Symbols.auto_awesome_rounded,
      'public' => Symbols.public_rounded,
      'forest' => Symbols.forest_rounded,
      'menu_book' => Symbols.menu_book_rounded,
      _ => Symbols.trophy_rounded,
    };

class _Summary extends StatelessWidget {
  const _Summary({required this.badges, required this.earned});
  final List<AchievementBadge> badges;
  final int earned;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = p.onRaised;
    final next = badges.where((b) => !b.unlocked).toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final closest = next.isEmpty ? null : next.first;
    return InkHeroCard(
      glowLevel: badges.isEmpty ? 0 : earned / badges.length,
      padding: const EdgeInsets.all(20),
      radius: AppSpacing.radiusTile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CountUpText(
                value: earned,
                animateFromZero: true,
                style: AppTypography.statNumber.copyWith(color: on),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('of ${badges.length}\nearned',
                    style: AppTypography.sans(
                        size: 15, weight: FontWeight.w600, height: 1.3, color: on.withValues(alpha: .75))),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ProgressSegments(total: badges.length, done: earned, maxSegments: 10),
          if (closest != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Closest: ${closest.title} · ${(closest.progress * 100).round()}%',
              style: AppTypography.metaStrong.copyWith(color: on.withValues(alpha: .7)),
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.onTap});
  final AchievementBadge badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final b = badge;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${b.title}, ${b.unlocked ? '${b.tierLabel}, earned' : '${(b.progress * 100).round()} percent'}',
      child: Container(
        // Grows with the text size so two-line titles never clip.
        height: 100 + 32 * MediaQuery.textScalerOf(context).scale(1),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: b.unlocked ? p.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          border: b.unlocked ? null : Border.all(color: p.outline, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BadgeIcon(badge: b, size: 40),
            const Spacer(),
            Text(b.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(
                    size: 13, weight: FontWeight.w700, height: 1.2,
                    color: b.unlocked ? p.textPrimary : p.textSecondary)),
            const SizedBox(height: 4),
            if (b.unlocked)
              Text(b.tierLabel, style: AppTypography.tiny.copyWith(color: p.textMuted))
            else
              GradientBar(value: b.progress, height: 4, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.badge, required this.size});
  final AchievementBadge badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final b = badge;
    if (!b.unlocked) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .35),
          border: Border.all(color: p.outline, width: 1.5),
        ),
        child: AtlasIcon(b.icon, size: size * .52, color: p.textMuted),
      );
    }
    if (b.tier == 'legendary') return GradientIconTile(icon: b.icon, size: size);
    return IconTile(style: CategoryStyle(b.icon, b.tierColor), size: size);
  }
}

void _showBadge(BuildContext context, AchievementBadge b) {
  showAtlasSheet<void>(
    context,
    builder: (context) {
      final p = context.palette;
      final pct = (b.progress * 100).round();
      final current = (b.progress * b.target).floor();
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BadgeIcon(badge: b, size: 72),
            const SizedBox(height: AppSpacing.md),
            Text(b.title,
                textAlign: TextAlign.center,
                style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
            const SizedBox(height: 6),
            Text(b.description,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: p.textBody)),
            const SizedBox(height: AppSpacing.md),
            AtlasChip(
              label: b.tierLabel,
              background: p.tint(b.tierColor),
              foreground: p.category(b.tierColor),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (b.unlocked)
              Text(
                b.unlockedAt == null ? 'Earned' : 'Earned ${longDate(b.unlockedAt!)}',
                style: AppTypography.metaStrong.copyWith(color: p.textMuted),
              )
            else ...[
              Row(children: [
                Text('$pct%', style: AppTypography.cardNumber.copyWith(color: p.textPrimary)),
                const Spacer(),
                if (b.target > 1)
                  Text('${current.clamp(0, b.target.toInt())} of ${b.target.toInt()}',
                      style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
              ]),
              const SizedBox(height: 10),
              GradientBar(value: b.progress, gradient: AppColors.sunriseBar),
            ],
          ],
        ),
      );
    },
  );
}
