import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';

/// One day in the Grow week strip.
class WeekDay {
  const WeekDay({required this.date, required this.value, required this.isFuture});
  final DateTime date;

  /// Completed habit check-ins ÷ habits scheduled that day.
  final double value;
  final bool isFuture;
}

/// The current ISO week (Monday first), with each day's completion.
final weekStripProvider = Provider.autoDispose<List<WeekDay>>((ref) {
  final today = ref.watch(todayProvider);
  final habits = ref.watch(habitsStreamProvider).value ?? const <Habit>[];
  final days = ref.watch(ledgerDaysProvider);
  final monday = startOfWeek(today);
  return [
    for (var i = 0; i < 7; i++)
      () {
        final d = addDays(monday, i);
        final future = d.isAfter(today);
        if (future) return WeekDay(date: d, value: 0, isFuture: true);
        final scheduled = habits
            .where((h) =>
                !dateOnly(h.createdAt).isAfter(d) &&
                !HabitSchedule.isWeekly(h.frequency) &&
                HabitSchedule.isScheduledOn(h.frequency, d))
            .toList();
        if (scheduled.isEmpty) return WeekDay(date: d, value: 0, isFuture: false);
        final done = scheduled.where((h) => habitDoneOn(h, d, today, days)).length;
        return WeekDay(date: d, value: done / scheduled.length, isFuture: false);
      }(),
  ];
});

/// Whether [h] was done on [day]: today reads the live flag, earlier days
/// read the ledger.
bool habitDoneOn(Habit h, DateTime day, DateTime today, List<LedgerDay> days) {
  if (isSameDay(day, today)) {
    return h.isCompletedToday &&
        HabitSchedule.doneInPeriod(h.frequency, h.lastCompletedDate, today);
  }
  return LedgerMath.dayOf(days, day)?.has(Ledger.habitKey(h.id)) ?? false;
}

/// The habit's last 7 days, ending on [day] (oldest first). Today's slot
/// follows the live flag so it updates the instant you tend.
List<bool> habitWeek(Habit h, DateTime day, DateTime today, List<LedgerDay> days) {
  final hist = LedgerMath.last7(days, Ledger.habitKey(h.id), day);
  if (isSameDay(day, today)) hist[6] = habitDoneOn(h, today, today, days);
  return hist;
}
