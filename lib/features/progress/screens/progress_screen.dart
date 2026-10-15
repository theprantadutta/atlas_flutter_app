import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/progress/providers/progress_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Progress: day by day. Each day shows how much of what was asked of it got
/// tended (a sunrise bar), the XP it earned, and what you did. Today is the
/// ink row. Reads the local ledger (source of truth).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(progressEntriesStreamProvider);
    final rows = ref.watch(dayByDayProvider);
    final today = ref.watch(todayProvider);
    final monday = startOfWeek(today);

    // Group into This week / Last week / Earlier.
    final groups = <(String, List<DayRow>)>[];
    for (final r in rows) {
      final label = !r.date.isBefore(monday)
          ? 'This week'
          : !r.date.isBefore(addDays(monday, -7))
              ? 'Last week'
              : 'Earlier';
      if (groups.isEmpty || groups.last.$1 != label) groups.add((label, []));
      groups.last.$2.add(r);
    }

    var index = 0;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.xxl),
          children: [
            ScreenHeader(title: 'Day by day', onBack: () => context.pop()),
            const SizedBox(height: AppSpacing.md),
            if (entries.isLoading && rows.isEmpty)
              const SkeletonList(count: 6)
            else if (rows.isEmpty)
              EmptyState(
                title: 'No days yet.',
                body: 'Tend something and your days fill in here.',
                actionLabel: 'Go to Grow',
                onAction: () => context.go('/grow'),
              )
            else
              for (final (label, days) in groups) ...[
                SectionTitle(label, padding: const EdgeInsets.fromLTRB(4, 4, 4, 0)),
                const SizedBox(height: AppSpacing.sm),
                for (final r in days)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: EntryFade(
                      id: 'day-${dayKey(r.date)}',
                      index: index++,
                      child: _DayRowView(row: r, isToday: isSameDay(r.date, today), today: today),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

String _dayLabel(DateTime d, DateTime today) {
  final diff = daysBetween(d, today);
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return weekdayName(d);
}

class _DayRowView extends StatelessWidget {
  const _DayRowView({required this.row, required this.isToday, required this.today});
  final DayRow row;
  final bool isToday;
  final DateTime today;

  String get _summary {
    if (row.tended == 0) return 'A quiet day';
    final shown = row.titles.take(2).join(', ');
    final more = row.tended - row.titles.take(2).length;
    if (shown.isEmpty) return '${row.tended} tended';
    return more > 0 ? '$shown and $more more' : shown;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = isToday ? p.onRaised : p.textPrimary;
    final muted = isToday ? p.onRaised.withValues(alpha: .65) : p.textMuted;
    final label = _dayLabel(row.date, today);

    return Pressable(
      onTap: row.tended == 0 ? null : () => _showDay(context),
      semanticLabel:
          '$label, ${row.xp} XP, ${(row.completion * 100).round()} percent, $_summary',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: isToday ? p.raised : p.paper,
          border: isToday ? p.raisedBorderSide : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.rowTitle.copyWith(color: fg)),
                      Text('${row.date.day} ${monthShort(row.date)}',
                          style: AppTypography.meta.copyWith(color: muted)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GradientBar(
                    value: row.completion,
                    gradient: AppColors.sunriseBar,
                    trackColor: isToday ? p.onRaised.withValues(alpha: .15) : p.track,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 72,
                  child: Text(
                    '+${row.xp} XP',
                    textAlign: TextAlign.right,
                    style: AppTypography.sans(
                        size: 15, weight: FontWeight.w700, tabular: true, color: fg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.meta.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }

  void _showDay(BuildContext context) {
    showAtlasSheet<void>(
      context,
      builder: (context) {
        final p = context.palette;
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(longDate(row.date), style: AppTypography.section.copyWith(color: p.textPrimary)),
              const SizedBox(height: 4),
              Text('+${row.xp} XP · ${row.tended} tended',
                  style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
              const SizedBox(height: AppSpacing.md),
              for (final t in row.titles)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: AtlasRow(
                    minHeight: 54,
                    leading: IconTile(style: CategoryStyle.forItem(title: t), size: 38),
                    title: t,
                  ),
                ),
              if (row.titles.length < row.tended)
                Text(
                  '${row.tended - row.titles.length} more that have since been removed',
                  style: AppTypography.meta.copyWith(color: p.textMuted),
                ),
            ],
          ),
        );
      },
    );
  }
}
