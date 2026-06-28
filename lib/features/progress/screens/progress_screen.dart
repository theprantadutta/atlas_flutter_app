import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/sample/sample_extra.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// Progress — a calm, day-by-day ledger of the week, with each day's XP shown
/// as a thin bar so days can be compared at a glance.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(progressProvider);
    final maxXp = days.fold<int>(0, (p, e) => e.xp > p ? e.xp : p);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            AtlasHeader(
              title: 'Progress',
              subtitle: 'Day by day',
              onBack: () => context.pop(),
            ),
            AppSpacing.gapLg,
            const SectionHeader(title: 'This week'),
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0) AppSpacing.gapSm,
              _DayCard(
                entry: days[i],
                maxXp: maxXp,
                isToday: days[i].label == 'Today',
              )
                  .animate(delay: Duration(milliseconds: 40 * i))
                  .fadeIn(duration: AppMotion.medium)
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: AppMotion.medium,
                    curve: AppMotion.standard,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.entry,
    required this.maxXp,
    required this.isToday,
  });

  final DayEntry entry;
  final int maxXp;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = maxXp == 0 ? 0.0 : entry.xp / maxXp;

    return AtlasCard(
      color:
          isToday ? theme.colorScheme.primary.withValues(alpha: 0.07) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                if (isToday)
                  const _TodayChip()
                else
                  Text(
                    entry.date,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: AtlasProgressBar(
              fraction: fraction,
              height: 8,
              color: isToday ? null : theme.colorScheme.primary,
              gradient: isToday ? AppColors.auroraGradient : null,
            ),
          ),
          AppSpacing.hGapMd,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${entry.xp} XP',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.xpPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.tasks} done · ${entry.streak}d',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        'Today',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
