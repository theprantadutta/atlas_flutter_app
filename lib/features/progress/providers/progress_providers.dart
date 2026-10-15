import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/goals/providers/goal_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';

/// Reactive stream of the current user's daily progress entries from Drift
/// (source of truth), most recent day first.
final progressEntriesStreamProvider =
    StreamProvider.autoDispose<List<ProgressEntry>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final dao = ref.read(progressDaoProvider);
  return dao.watchEntries(userId);
});

// ─── Day by day ─────────────────────────────────────────────────────

/// One day in the Progress list.
class DayRow {
  const DayRow({
    required this.date,
    required this.xp,
    required this.tended,
    required this.completion,
    required this.titles,
  });

  final DateTime date;
  final int xp;
  final int tended;

  /// Done ÷ what was scheduled that day, 0..1.
  final double completion;

  /// What was tended, in the order it was recorded.
  final List<String> titles;
}

/// How many days back the list goes.
const kDayByDayWindow = 28;

/// The last [kDayByDayWindow] days, newest first, stopping at the first day
/// the ledger knows about so a new account isn't a wall of empty rows.
final dayByDayProvider = Provider.autoDispose<List<DayRow>>((ref) {
  final today = ref.watch(todayProvider);
  final days = ref.watch(ledgerDaysProvider);
  final habits = ref.watch(habitsStreamProvider).value ?? const <Habit>[];
  final tasks = ref.watch(tasksStreamProvider).value ?? const <Task>[];
  final goals = ref.watch(goalsStreamProvider).value ?? const <Goal>[];
  if (days.isEmpty) return const [];

  final titles = <String, String>{
    for (final h in habits) Ledger.habitKey(h.id): h.title,
    for (final t in tasks) Ledger.taskKey(t.id): t.title,
    for (final g in goals) Ledger.goalKey(g.id): g.title,
  };
  final earliest = days.map((d) => d.date).reduce((a, b) => a.isBefore(b) ? a : b);

  final rows = <DayRow>[];
  for (var i = 0; i < kDayByDayWindow; i++) {
    final d = addDays(today, -i);
    if (d.isBefore(earliest)) break;
    final day = LedgerMath.dayOf(days, d);
    final scheduled = habits
            .where((h) =>
                !dateOnly(h.createdAt).isAfter(d) &&
                !HabitSchedule.isWeekly(h.frequency) &&
                HabitSchedule.isScheduledOn(h.frequency, d))
            .length +
        tasks.where((t) => t.type == 'daily' && !dateOnly(t.createdAt).isAfter(d)).length;
    final count = day?.count ?? 0;
    rows.add(DayRow(
      date: d,
      xp: day?.xp ?? 0,
      tended: count,
      completion: scheduled == 0 ? (count > 0 ? 1 : 0) : (count / scheduled).clamp(0.0, 1.0),
      titles: [
        for (final k in day?.items.keys ?? const <String>[]) ?titles[k],
      ],
    ));
  }
  return rows;
});
