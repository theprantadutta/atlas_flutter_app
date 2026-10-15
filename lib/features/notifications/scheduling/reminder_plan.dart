import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/notifications/data/notify_prefs.dart';

/// What a scheduled reminder is about. Each kind has its own switch in
/// Settings and its own Android channel.
enum ReminderKind { habit, task, morning, letter }

/// One notification the device should have scheduled.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.kind,
    required this.at,
    required this.title,
    required this.body,
    required this.route,
  });

  /// Stable for the same thing on the same day, so re-planning replaces a
  /// reminder rather than stacking a second one.
  final int id;
  final ReminderKind kind;
  final DateTime at;
  final String title;
  final String body;
  final String route;

  @override
  String toString() => 'PlannedReminder($kind, $at, $title: $body)';
}

/// The whole reminder schedule, worked out from what is on the device.
///
/// Rules, in the spirit of the app (a small sunrise, never a nag):
/// * Only at times the user chose: a habit's own reminder time, a task's due
///   time, and their morning time for the morning note and the weekly letter.
///   Nothing lands at an hour nobody picked, so there is no need for quiet
///   hours.
/// * Never about something already done: today's reminder for a habit or task
///   that is finished is dropped, and the morning note leaves done items out.
/// * Never about a streak, a miss or a count of what is left undone.
/// * An empty day sends nothing.
///
/// The plan covers [horizonDays] days, so reminders keep coming if the app is
/// not opened for a day or two, and then go quiet when someone steps away.
/// It is capped at [budget] because iOS keeps only 64 pending notifications.
class ReminderPlanner {
  const ReminderPlanner({this.horizonDays = 3, this.budget = 48});

  final int horizonDays;
  final int budget;

  List<PlannedReminder> plan({
    required DateTime now,
    required List<Habit> habits,
    required List<Task> tasks,
    required NotifyPrefs prefs,
    String? firstName,
    bool activeThisWeek = false,
  }) {
    final today = dateOnly(now);
    final out = <PlannedReminder>[];

    for (var i = 0; i < horizonDays; i++) {
      final day = addDays(today, i);

      if (prefs.habits) {
        for (final h in habits) {
          final t = parseHm(h.reminderTime);
          if (t == null || !_habitDueOn(h, day, today)) continue;
          out.add(PlannedReminder(
            id: reminderId('habit:${h.id}:${_ymd(day)}'),
            kind: ReminderKind.habit,
            at: DateTime(day.year, day.month, day.day, t.hour, t.minute),
            title: h.title,
            body: _gentle(day, h.id),
            route: '/grow',
          ));
        }
      }

      if (prefs.morning) {
        final items = [
          for (final h in habits)
            if (_habitDueOn(h, day, today)) h.title,
          for (final t in tasks)
            if (_taskOnDay(t, day, today)) t.title,
        ];
        if (items.isNotEmpty) {
          out.add(PlannedReminder(
            id: reminderId('morning:${_ymd(day)}'),
            kind: ReminderKind.morning,
            at: DateTime(day.year, day.month, day.day, prefs.morningHour, prefs.morningMinute),
            title: firstName == null || firstName.isEmpty ? 'Good morning' : 'Good morning, $firstName',
            body: morningLine(items),
            route: '/',
          ));
        }
      }
    }

    if (prefs.tasks) {
      final end = addDays(today, horizonDays);
      for (final t in tasks) {
        final due = t.dueDate;
        if (due == null || (due.hour == 0 && due.minute == 0)) continue; // no time set
        if (!due.isBefore(end) || _taskDone(t, dateOnly(due))) continue;
        out.add(PlannedReminder(
          id: reminderId('task:${t.id}:${due.toIso8601String()}'),
          kind: ReminderKind.task,
          at: due,
          title: t.title,
          body: 'It’s time, if now works for you.',
          route: '/grow',
        ));
      }
    }

    if (prefs.letter && activeThisWeek) {
      // Sunday at the morning time: the week is done, the letter is ready.
      var sunday = addDays(today, (DateTime.sunday - today.weekday) % 7);
      var at = DateTime(sunday.year, sunday.month, sunday.day, prefs.morningHour, prefs.morningMinute);
      if (!at.isAfter(now)) {
        sunday = addDays(sunday, 7);
        at = DateTime(sunday.year, sunday.month, sunday.day, prefs.morningHour, prefs.morningMinute);
      }
      out.add(PlannedReminder(
        id: reminderId('letter:${_ymd(sunday)}'),
        kind: ReminderKind.letter,
        at: at,
        title: 'Your weekly letter',
        body: 'Aurora is ready to look back on your week with you.',
        route: '/aurora',
      ));
    }

    final future = out.where((r) => r.at.isAfter(now)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    return future.take(budget).toList();
  }

  /// "Today: Move your body, Read 20 pages and 2 more."
  static String morningLine(List<String> items) {
    if (items.length == 1) return 'One small thing today: ${items.first}.';
    if (items.length == 2) return 'Today: ${items[0]} and ${items[1]}.';
    return 'Today: ${items[0]}, ${items[1]} and ${items.length - 2} more.';
  }

  /// Whether [h] is something to do on [day], as Home would show it.
  static bool _habitDueOn(Habit h, DateTime day, DateTime today) {
    if (!HabitSchedule.isScheduledOn(h.frequency, day)) return false;
    if (dateOnly(h.createdAt).isAfter(day)) return false;
    if (HabitSchedule.isWeekly(h.frequency)) {
      // Once a week, on the weekday it was made, until it's done that week.
      if (day.weekday != h.createdAt.weekday) return false;
      return !HabitSchedule.doneInPeriod(h.frequency, h.lastCompletedDate, day);
    }
    // Done today means nothing more to say today. Future days start fresh.
    if (isSameDay(day, today)) {
      return !HabitSchedule.doneInPeriod(h.frequency, h.lastCompletedDate, today);
    }
    return true;
  }

  static bool _taskDone(Task t, DateTime day) =>
      t.isCompleted && TaskSchedule.doneInPeriod(t.type, t.lastCompletedDate, day);

  static bool _taskOnDay(Task t, DateTime day, DateTime today) {
    final isToday = isSameDay(day, today);
    // Future days: a recurring task comes back, a one-off does not.
    if (isToday ? _taskDone(t, today) : (t.isCompleted && t.type != 'daily' && t.type != 'weekly')) {
      return false;
    }
    final due = t.dueDate;
    if (due != null) {
      if (isSameDay(due, day)) return true;
      // Something overdue belongs on today's list, not on every later day.
      return isToday && dateOnly(due).isBefore(today);
    }
    return t.type == 'daily';
  }

  static const _lines = [
    'A small moment for you, whenever you’re ready.',
    'Here if you’d like it today.',
    'No rush. Just a gentle nudge.',
    'Whenever it suits you.',
  ];

  /// A kind line that changes from day to day and habit to habit, so the same
  /// reminder never reads like a machine.
  static String _gentle(DateTime day, String seed) =>
      _lines[(day.day + day.month + seed.codeUnits.fold<int>(0, (a, c) => a + c)) % _lines.length];

  static String _ymd(DateTime d) => dayKey(d);
}

/// A stable, positive 31-bit id for [key] (FNV-1a). Ids below 2^30 are
/// managed by the planner; Aurora's one-off nudges use the upper half.
int reminderId(String key) {
  var h = 0x811c9dc5;
  for (final c in key.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h & 0x3FFFFFFF;
}
