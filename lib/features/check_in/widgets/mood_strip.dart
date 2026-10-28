import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// "How the week felt": one dot per day, oldest to newest, coloured by that
/// day's mood (an empty ring when there was no check-in). Never graded:
/// the dots don't rise or fall, they're just the colour of the day.
class WeekMoodStrip extends StatelessWidget {
  const WeekMoodStrip({
    super.key,
    required this.moods,
    required this.today,
    this.onCheckIn,
  });

  /// 7 entries, oldest first, ending [today]; null means no check-in.
  final List<int?> moods;
  final DateTime today;

  /// Opens a check-in from the empty state.
  final VoidCallback? onCheckIn;

  static const _dot = 28.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final empty = moods.every((m) => m == null);
    final start = addDays(today, -(moods.length - 1));
    final present = {for (final m in moods) ?m}.toList()..sort();

    return AtlasTile(
      radius: AppSpacing.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('How the week felt',
                    style: AppTypography.sans(
                        size: 14, weight: FontWeight.w700, color: p.textPrimary)),
              ),
              Text('Last 7 days',
                  style: AppTypography.meta.copyWith(color: p.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < moods.length; i++)
                Expanded(
                  child: _Day(
                    mood: moods[i],
                    day: addDays(start, i),
                    isToday: i == moods.length - 1,
                    size: _dot,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (empty)
            Row(
              children: [
                Expanded(
                  child: Text('Check in once and your week starts to show here.',
                      style: AppTypography.meta.copyWith(color: p.textMuted)),
                ),
                if (onCheckIn != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  PillButton(
                    label: 'Check in',
                    height: 34,
                    variant: PillVariant.track,
                    onTap: onCheckIn,
                  ),
                ],
              ],
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: AppSpacing.xs,
              children: [
                for (final m in present)
                  LegendDot(color: p.mood(m), label: CheckInMood.labels[m]!),
              ],
            ),
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.mood,
    required this.day,
    required this.isToday,
    required this.size,
  });

  final int? mood;
  final DateTime day;
  final bool isToday;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final m = mood;
    final label = m == null
        ? '${weekdayName(day)}: no check-in'
        : '${weekdayName(day)}: ${CheckInMood.labels[m]}';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            key: ValueKey('mood-dot-$m'),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: m == null ? null : p.mood(m),
              border: m == null ? Border.all(color: p.outline, width: 2) : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(weekdayLetter(day),
              style: AppTypography.metaStrong.copyWith(
                  color: isToday ? p.textPrimary : p.textMuted)),
        ],
      ),
    );
  }
}
