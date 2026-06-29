import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/sample/sample_extra.dart' show DayEntry;
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/progress/providers/progress_providers.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// Progress — a calm, day-by-day ledger of the week, with each day's XP shown
/// as a thin bar so days can be compared at a glance. Reads the local-first
/// Drift ledger (source of truth).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(progressEntriesStreamProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Could not load your progress')),
          data: (rows) {
            final today = DateTime.now();
            final days = rows.map((r) => _toDay(r, today)).toList();
            final maxXp = days.fold<int>(0, (p, e) => e.xp > p ? e.xp : p);

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.bottomNavSpace,
              ),
              children: [
                AtlasHeader(
                  title: 'Progress',
                  subtitle: 'Day by day',
                  onBack: () => context.pop(),
                ),
                AppSpacing.gapLg,
                const SectionHeader(title: 'This week'),
                if (days.isEmpty)
                  const AtlasEmptyState(
                    icon: Icons.timeline_rounded,
                    title: 'No history yet',
                    message: 'Tend your habits and your week will fill in here.',
                  )
                else
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
            );
          },
        ),
      ),
    );
  }
}

/// Map a Drift progress row to the ledger view model, labelling the day
/// relative to today.
DayEntry _toDay(ProgressEntry row, DateTime today) {
  return DayEntry(
    label: _labelFor(row.date, today),
    date: _dateStr(row.date),
    xp: row.xpGained,
    tasks: row.tasksCompleted,
    streak: row.streakCount,
  );
}

String _labelFor(DateTime date, DateTime today) {
  final d = DateTime(date.year, date.month, date.day);
  final t = DateTime(today.year, today.month, today.day);
  final diff = t.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[d.weekday - 1];
}

String _dateStr(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
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
