import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/features/notifications/data/notify_prefs.dart';
import 'package:atlas_flutter_app/features/notifications/scheduling/reminder_plan.dart';

import '../../helpers/sample_data.dart';

void main() {
  const planner = ReminderPlanner();
  const prefs = NotifyPrefs(loaded: true);
  // Tuesday 14 Oct 2025, 6am: before everything.
  final dawn = kToday.add(const Duration(hours: 6));

  List<PlannedReminder> plan({
    DateTime? now,
    List habits = const [],
    List tasks = const [],
    NotifyPrefs p = prefs,
    bool active = false,
  }) =>
      planner.plan(
        now: now ?? dawn,
        habits: habits.cast(),
        tasks: tasks.cast(),
        prefs: p,
        firstName: 'John',
        activeThisWeek: active,
      );

  test('a habit reminds at its own time on each of the next three days', () {
    final out = plan(habits: [habit('h1', 'Move your body', 'fitness', time: '07:30')])
        .where((r) => r.kind == ReminderKind.habit)
        .toList();
    expect(out.map((r) => r.at), [
      for (var i = 0; i < 3; i++) addDays(kToday, i).add(const Duration(hours: 7, minutes: 30)),
    ]);
    expect(out.first.title, 'Move your body');
    expect(out.first.route, '/grow');
  });

  test('a habit already done today is not reminded today, but is tomorrow', () {
    final out = plan(habits: [habit('h1', 'Stretch', 'fitness', time: '07:30', done: true)])
        .where((r) => r.kind == ReminderKind.habit)
        .toList();
    expect(out.map((r) => dateOnly(r.at)), [addDays(kToday, 1), addDays(kToday, 2)]);
  });

  test('a habit with no time set never reminds', () {
    expect(plan(habits: [habit('h1', 'Read', 'learning')]).where((r) => r.kind == ReminderKind.habit), isEmpty);
  });

  test('weekday habits skip the weekend', () {
    // Thursday: the next three days are Thu, Fri, Sat.
    final thu = addDays(kToday, 2).add(const Duration(hours: 6));
    final out = plan(now: thu, habits: [habit('h1', 'Commute walk', 'fitness', time: '08:00', frequency: 'weekdays')])
        .where((r) => r.kind == ReminderKind.habit);
    expect(out.map((r) => r.at.weekday), [DateTime.thursday, DateTime.friday]);
  });

  test('a time already past today is not scheduled', () {
    final noon = kToday.add(const Duration(hours: 12));
    final out = plan(now: noon, habits: [habit('h1', 'Walk', 'fitness', time: '07:30')]);
    expect(out.every((r) => r.at.isAfter(noon)), isTrue);
  });

  test('the morning note lists the day, and an empty day sends nothing', () {
    final out = plan(habits: [
      habit('h1', 'Move your body', 'fitness'),
      habit('h2', 'Drink water', 'health'),
      habit('h3', 'Read', 'learning'),
    ]).where((r) => r.kind == ReminderKind.morning).toList();
    expect(out, hasLength(3));
    expect(out.first.at, kToday.add(const Duration(hours: 8)));
    expect(out.first.title, 'Good morning, John');
    expect(out.first.body, 'Today: Move your body, Drink water and 1 more.');

    expect(plan().where((r) => r.kind == ReminderKind.morning), isEmpty);
  });

  test('the morning note leaves out what is already done', () {
    final out = plan(habits: [
      habit('h1', 'Move your body', 'fitness', done: true),
      habit('h2', 'Drink water', 'health'),
    ]).firstWhere((r) => r.kind == ReminderKind.morning);
    expect(out.body, 'One small thing today: Drink water.');
  });

  test('a timed task reminds at its due time; a done or untimed one does not', () {
    final at = kToday.add(const Duration(hours: 15, minutes: 30));
    final out = plan(tasks: [
      task('t1', 'Call the bank', 'work', type: 'longTerm', due: at),
      task('t2', 'Book the dentist', 'health', type: 'longTerm', due: kToday),
      task('t3', 'Send invoice', 'work', type: 'longTerm', due: at, done: true),
    ]).where((r) => r.kind == ReminderKind.task).toList();
    expect(out, hasLength(1));
    expect(out.single.title, 'Call the bank');
    expect(out.single.at, at);
  });

  test('the weekly letter comes on Sunday morning, only after an active week', () {
    expect(plan().where((r) => r.kind == ReminderKind.letter), isEmpty);
    final letter = plan(active: true).singleWhere((r) => r.kind == ReminderKind.letter);
    expect(letter.at.weekday, DateTime.sunday);
    expect(letter.at.hour, 8);
    expect(letter.route, '/aurora');
  });

  test('switching a kind off removes it', () {
    final out = plan(
      habits: [habit('h1', 'Walk', 'fitness', time: '07:30')],
      p: prefs.copyWith(habits: false, morning: false),
      active: true,
    );
    expect(out.map((r) => r.kind).toSet(), {ReminderKind.letter});
  });

  test('the same reminder keeps the same id when planned again', () {
    final h = [habit('h1', 'Walk', 'fitness', time: '07:30')];
    expect(plan(habits: h).map((r) => r.id), plan(habits: h).map((r) => r.id));
    final ids = plan(habits: h).map((r) => r.id).toList();
    expect(ids.toSet(), hasLength(ids.length), reason: 'one per day, no collisions');
    expect(ids.every((id) => id >= 0 && id < 1 << 30), isTrue);
  });

  test('the plan stays within the budget, soonest first', () {
    final many = [for (var i = 0; i < 30; i++) habit('h$i', 'Habit $i', 'fitness', time: '09:00')];
    final out = plan(habits: many);
    expect(out, hasLength(48));
    for (var i = 1; i < out.length; i++) {
      expect(out[i].at.isBefore(out[i - 1].at), isFalse);
    }
  });

  test('no copy uses dashes or talks about streaks', () {
    final out = plan(
      habits: [habit('h1', 'Walk', 'fitness', time: '07:30'), habit('h2', 'Read', 'learning')],
      tasks: [task('t1', 'Call', 'work', type: 'longTerm', due: kToday.add(const Duration(hours: 15)))],
      active: true,
    );
    for (final r in out) {
      expect('${r.title} ${r.body}', isNot(matches(RegExp('[–—]|streak', caseSensitive: false))));
    }
  });
}
