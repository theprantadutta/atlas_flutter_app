import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/home/providers/home_prefs.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/category_style.dart';

// ─── Home view-model ────────────────────────────────────────────────
//
// Derived entirely from local Drift (the source of truth) plus a few device
// prefs. Recomputes reactively whenever a table changes or the day rolls.

enum TodayKind { task, habit }

/// One thing to tend today: a task due today or a habit scheduled today.
class TodayItem {
  const TodayItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.style,
    required this.xp,
    required this.done,
    required this.createdAt,
    this.minuteOfDay,
    this.snoozed = false,
    this.task,
    this.habit,
  });

  final String id;
  final TodayKind kind;
  final String title;
  final CategoryStyle style;
  final int xp;
  final bool done;
  final DateTime createdAt;

  /// Scheduled time, in minutes after midnight, if it has one.
  final int? minuteOfDay;
  final bool snoozed;
  final Task? task;
  final Habit? habit;

  String get timeLabel => minuteOfDay == null
      ? 'Anytime'
      : clockLabel(minuteOfDay! ~/ 60, minuteOfDay! % 60);

  String get meta => '$timeLabel · +$xp XP';
}

/// What the letter tile shows.
enum LetterTileState { unread, talk }

class HomeView {
  const HomeView({
    required this.today,
    required this.firstName,
    required this.items,
    required this.stats,
    required this.letter,
    required this.letterId,
    this.ready = true,
  });

  final DateTime today;
  final String firstName;
  final List<TodayItem> items;
  final PlayerStats stats;
  final LetterTileState letter;
  final String? letterId;

  /// False until both tasks and habits have loaded. Until then the list is
  /// partial, so Home must not judge the day: no "All tended", no empty
  /// state and no celebration from whichever stream happened to arrive first.
  final bool ready;

  int get total => items.length;
  int get done => items.where((i) => i.done).length;
  double get progress => total == 0 ? 0 : done / total;
  int get percent => (progress * 100).round();
  bool get dayComplete => ready && total > 0 && done == total;

  /// Not-done items: by scheduled time (untimed last), then creation date;
  /// snoozed ones sink to the end.
  List<TodayItem> get remaining {
    final list = items.where((i) => !i.done).toList()
      ..sort((a, b) {
        if (a.snoozed != b.snoozed) return a.snoozed ? 1 : -1;
        final at = a.minuteOfDay, bt = b.minuteOfDay;
        if (at != bt) {
          if (at == null) return 1;
          if (bt == null) return -1;
          return at.compareTo(bt);
        }
        return a.createdAt.compareTo(b.createdAt);
      });
    return list;
  }
}

int? _minuteOf(DateTime? d) {
  if (d == null) return null;
  final m = d.hour * 60 + d.minute;
  return m == 0 ? null : m; // a date without a time
}

int? _minuteOfHm(String? hm) {
  final t = parseHm(hm);
  return t == null ? null : t.hour * 60 + t.minute;
}

/// Whether a task belongs on today's list: recurring daily tasks, anything
/// due today or overdue and still open, and anything finished today.
bool _taskIsToday(Task t, DateTime today) {
  final done = t.isCompleted && TaskSchedule.doneInPeriod(t.type, t.lastCompletedDate, today);
  if (done) {
    final last = t.lastCompletedDate;
    return last != null && isSameDay(last, today);
  }
  final due = t.dueDate;
  if (due != null) return !dateOnly(due).isAfter(today);
  return t.type == 'daily';
}

final homeProvider = Provider.autoDispose<HomeView>((ref) {
  final today = ref.watch(todayProvider);
  final user = ref.watch(authProvider.select((s) => s.user));
  final tasksAsync = ref.watch(tasksStreamProvider);
  final habitsAsync = ref.watch(habitsStreamProvider);
  final tasks = tasksAsync.value ?? const <Task>[];
  final habits = habitsAsync.value ?? const <Habit>[];
  final stats = ref.watch(playerStatsProvider);
  final snoozed = ref.watch(snoozeProvider);
  final reflection = ref.watch(latestReflectionProvider).value;
  final lastRead = ref.watch(letterReadProvider);
  final now = DateTime.now();
  bool isSnoozed(String id) => snoozed[id]?.isAfter(now) ?? false;

  final items = <TodayItem>[
    for (final t in tasks)
      if (_taskIsToday(t, today))
        TodayItem(
          id: t.id,
          kind: TodayKind.task,
          title: t.title,
          style: CategoryStyle.forItem(title: t.title, category: t.category),
          xp: t.xpReward,
          done: t.isCompleted && TaskSchedule.doneInPeriod(t.type, t.lastCompletedDate, today),
          createdAt: t.createdAt,
          minuteOfDay: _minuteOf(t.dueDate),
          snoozed: isSnoozed(t.id),
          task: t,
        ),
    for (final h in habits)
      if (HabitSchedule.isScheduledOn(h.frequency, today) &&
          // A weekly habit already done this week isn't "today's" any more,
          // unless it was done today.
          (!HabitSchedule.isWeekly(h.frequency) ||
              !HabitSchedule.doneInPeriod(h.frequency, h.lastCompletedDate, today) ||
              isSameDay(h.lastCompletedDate ?? DateTime(0), today)))
        TodayItem(
          id: h.id,
          kind: TodayKind.habit,
          title: h.title,
          style: CategoryStyle.forItem(title: h.title, category: h.category),
          xp: GamificationConstants.calculateHabitXp(
            difficulty: h.difficulty,
            streakCount: HabitSchedule.nextStreak(
                    h.frequency, h.lastCompletedDate, h.streakCount, today) -
                1,
          ),
          done: h.isCompletedToday &&
              HabitSchedule.doneInPeriod(h.frequency, h.lastCompletedDate, today),
          createdAt: h.createdAt,
          minuteOfDay: _minuteOfHm(h.reminderTime),
          snoozed: isSnoozed(h.id),
          habit: h,
        ),
  ];

  final name = user?.fullName.trim() ?? '';
  final firstName = name.isEmpty ? 'there' : name.split(RegExp(r'\s+')).first;

  final unread = reflection != null && lastRead != null && reflection.id != lastRead;

  return HomeView(
    today: today,
    firstName: firstName,
    items: items,
    stats: stats,
    letter: unread ? LetterTileState.unread : LetterTileState.talk,
    letterId: reflection?.id,
    ready: tasksAsync.hasValue && habitsAsync.hasValue,
  );
});
