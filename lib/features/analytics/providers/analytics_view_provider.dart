import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/category_style.dart';

/// One category's share of the week's XP.
class CategorySlice {
  const CategorySlice(this.label, this.xp, this.color);
  final String label;
  final int xp;
  final Color color;
}

/// A week of insights, from the local ledger.
class WeekInsights {
  const WeekInsights({
    required this.weekStart,
    required this.xpByDay,
    required this.tendedByDay,
    required this.categories,
    required this.completion,
    required this.trendPercent,
    required this.today,
  });

  /// Monday.
  final DateTime weekStart;
  final List<int> xpByDay; // Mon..Sun
  final List<int> tendedByDay;
  final List<CategorySlice> categories;

  /// Done ÷ set for the days so far, 0..1.
  final double completion;

  /// Change vs the previous week as a whole percentage, or null when there
  /// is nothing to compare with.
  final int? trendPercent;
  final DateTime today;

  int get totalXp => xpByDay.fold(0, (a, b) => a + b);
  int get isoWeekNumber => isoWeek(weekStart);
  DateTime dayAt(int i) => addDays(weekStart, i);
  bool isFuture(int i) => dayAt(i).isAfter(today);

  /// The best day (ties go to the latest), or -1 before any XP.
  int get bestIndex {
    var best = -1, bestXp = 0;
    for (var i = 0; i < 7; i++) {
      if (xpByDay[i] > 0 && xpByDay[i] >= bestXp) {
        best = i;
        bestXp = xpByDay[i];
      }
    }
    return best;
  }
}

/// The week being viewed (its Monday). Defaults to this week.
class SelectedWeek extends Notifier<DateTime> {
  @override
  DateTime build() => startOfWeek(ref.watch(todayProvider));
  void set(DateTime monday) => state = startOfWeek(monday);
}

final selectedWeekProvider = NotifierProvider<SelectedWeek, DateTime>(SelectedWeek.new);

int _sumXp(List<LedgerDay> days, DateTime from, int n) {
  var s = 0;
  for (var i = 0; i < n; i++) {
    s += LedgerMath.dayOf(days, addDays(from, i))?.xp ?? 0;
  }
  return s;
}

final weekInsightsProvider = Provider.autoDispose.family<WeekInsights, DateTime>((ref, monday) {
  final today = ref.watch(todayProvider);
  final days = ref.watch(ledgerDaysProvider);
  final habits = ref.watch(habitsStreamProvider).value ?? const <Habit>[];
  final tasks = ref.watch(tasksStreamProvider).value ?? const <Task>[];

  final xp = <int>[], tended = <int>[];
  final cats = <String, int>{};
  var done = 0, set = 0;
  for (var i = 0; i < 7; i++) {
    final d = addDays(monday, i);
    final day = LedgerMath.dayOf(days, d);
    xp.add(day?.xp ?? 0);
    tended.add(day?.count ?? 0);
    day?.categories.forEach((k, v) => cats.update(k, (x) => x + v, ifAbsent: () => v));
    if (d.isAfter(today)) continue;
    done += day?.count ?? 0;
    // What was asked of this day: daily-ish habits and recurring daily tasks
    // that existed by then.
    set += habits
        .where((h) =>
            !dateOnly(h.createdAt).isAfter(d) &&
            !HabitSchedule.isWeekly(h.frequency) &&
            HabitSchedule.isScheduledOn(h.frequency, d))
        .length;
    set += tasks.where((t) => t.type == 'daily' && !dateOnly(t.createdAt).isAfter(d)).length;
  }
  final end = addDays(monday, 6);
  set += habits
      .where((h) => HabitSchedule.isWeekly(h.frequency) && !dateOnly(h.createdAt).isAfter(end))
      .length;
  set += tasks.where((t) {
    final due = t.dueDate;
    return t.type != 'daily' &&
        due != null &&
        !dateOnly(due).isBefore(monday) &&
        !dateOnly(due).isAfter(end);
  }).length;

  // Compare like with like: this week so far against the same days last week.
  final daysSoFar =
      today.isBefore(monday) ? 7 : (daysBetween(monday, today) + 1).clamp(1, 7);
  final current = _sumXp(days, monday, daysSoFar);
  final previous = _sumXp(days, addDays(monday, -7), daysSoFar);
  final trend = previous > 0 ? (((current - previous) / previous) * 100).round() : null;

  final sorted = cats.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final slices = <CategorySlice>[
    for (final e in sorted.take(3))
      CategorySlice(
          CategoryStyle.label(e.key), e.value, CategoryStyle.forCategory(e.key).color),
  ];
  final rest = sorted.skip(3).fold<int>(0, (a, e) => a + e.value);
  if (rest > 0) slices.add(CategorySlice('Other', rest, const Color(0xFFB3ADA2)));

  return WeekInsights(
    weekStart: monday,
    xpByDay: xp,
    tendedByDay: tended,
    categories: slices,
    completion: set == 0 ? 0 : (done / set).clamp(0.0, 1.0),
    trendPercent: trend,
    today: today,
  );
});
