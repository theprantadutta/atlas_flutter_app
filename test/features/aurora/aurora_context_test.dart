import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/aurora_memory_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/check_in_dao.dart';
import 'package:atlas_flutter_app/data/services/xp_ledger_service.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_context.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_memory_repository.dart';
import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';

void main() {
  late AtlasDatabase db;
  late AuroraContextBuilder builder;
  final now = DateTime(2026, 10, 28, 9, 15); // a Wednesday
  final today = dateOnly(now);
  final created = DateTime(2026, 9, 1);

  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    builder = AuroraContextBuilder(db);
  });

  tearDown(() => db.close());

  Future<void> habit(String id, String title,
      {DateTime? last, int streak = 0, DateTime? createdAt}) =>
      db.into(db.habits).insert(HabitsCompanion.insert(
            id: id,
            userId: 'u1',
            title: title,
            category: 'health',
            frequency: 'daily',
            streakCount: Value(streak),
            lastCompletedDate: Value(last),
            createdAt: createdAt ?? created,
            updatedAt: created,
          ));

  Future<void> task(String id, String title,
      {bool done = false, DateTime? last, String type = 'daily', DateTime? createdAt}) =>
      db.into(db.tasks).insert(TasksCompanion.insert(
            id: id,
            userId: 'u1',
            title: title,
            type: type,
            category: 'social',
            isCompleted: Value(done),
            lastCompletedDate: Value(last),
            createdAt: createdAt ?? created,
            updatedAt: created,
          ));

  Future<Map<String, dynamic>> build({bool premium = false,
          AuroraContextPeriod period = AuroraContextPeriod.week}) =>
      builder.build(
          userId: 'u1', includeMemories: premium, period: period, now: now);

  test('header fields', () async {
    final c = await build();
    expect(c['today'], '2026-10-28');
    expect(c['weekday'], 'Wednesday');
    expect(c['local_time'], '09:15');
    expect(c['habits'], isEmpty);
    expect(c['tasks'], isEmpty);
    expect(c['goals'], isEmpty);
    expect(c['moods'], isEmpty);
    expect(c.containsKey('week'), isTrue);
    expect(c.containsKey('memories'), isFalse);
  });

  test('done_last_7 counts ledger completions in the last 7 local days',
      () async {
    await habit('h1', 'Morning run', last: today, streak: 4);
    final ledger = XpLedgerService(db);
    // 5 days inside the window (today and 4 earlier), 1 outside it.
    for (final back in [0, 1, 2, 4, 6, 7]) {
      await ledger.record(
          userId: 'u1',
          itemKey: 'h:h1',
          xp: 10,
          category: 'health',
          type: 'habit',
          day: addDays(today, -back));
    }
    final h = ((await build())['habits'] as List).single as Map;
    expect(h['id'], 'h1');
    expect(h['done_today'], isTrue);
    expect(h['streak'], 4);
    expect(h['done_last_7'], 5);
  });

  test('a lapsed streak is sent as 0; undone habits come first', () async {
    await habit('done', 'Water', last: today, streak: 3);
    await habit('lapsed', 'Read',
        last: addDays(today, -5), streak: 9, createdAt: DateTime(2026, 9, 2));
    final habits = (await build())['habits'] as List;
    expect(habits.map((h) => h['id']), ['lapsed', 'done']);
    expect((habits.first as Map)['streak'], 0);
    expect((habits.first as Map)['done_today'], isFalse);
  });

  test('tasks: open first, then today\'s done; older done ones left out',
      () async {
    await task('doneToday', 'Call mum', done: true, last: now);
    await task('open', 'Pay rent');
    await task('doneLong', 'Plant tree',
        done: true, last: DateTime(2026, 9, 3), type: 'longTerm');
    final tasks = (await build())['tasks'] as List;
    expect(tasks.map((t) => t['id']), ['open', 'doneToday']);
    expect((tasks.last as Map)['done'], isTrue);
  });

  test('caps: habits 30, tasks 30, goals 15, titles 80', () async {
    for (var i = 0; i < 35; i++) {
      await habit('h$i', 'Habit $i ${'x' * 100}');
      await task('t$i', 'Task $i');
    }
    for (var i = 0; i < 20; i++) {
      await db.into(db.goals).insert(GoalsCompanion.insert(
            id: 'g$i',
            userId: 'u1',
            title: 'Goal $i',
            category: 'health',
            priority: 'medium',
            status: 'inProgress',
            progress: const Value(40),
            createdAt: created,
            updatedAt: created,
          ));
    }
    final c = await build();
    expect(c['habits'], hasLength(30));
    expect(c['tasks'], hasLength(30));
    expect(c['goals'], hasLength(15));
    expect(((c['habits'] as List).first as Map)['title'], hasLength(80));
    expect(((c['goals'] as List).first as Map)['progress'], 0.4);
  });

  test('goals skip completed ones and carry the target date', () async {
    await db.into(db.goals).insert(GoalsCompanion.insert(
          id: 'g1',
          userId: 'u1',
          title: 'Run a 10k',
          category: 'health',
          priority: 'high',
          status: 'inProgress',
          progress: const Value(0.4),
          deadline: Value(DateTime(2026, 12, 31)),
          createdAt: created,
          updatedAt: created,
        ));
    await db.into(db.goals).insert(GoalsCompanion.insert(
          id: 'g2',
          userId: 'u1',
          title: 'Done one',
          category: 'health',
          priority: 'high',
          status: 'completed',
          createdAt: created,
          updatedAt: created,
        ));
    final goals = (await build())['goals'] as List;
    expect(goals, hasLength(1));
    expect(goals.single,
        containsPair('target_date', '2026-12-31'));
  });

  test('untrusted text is cleaned (line breaks, quotes, length)', () {
    expect(AuroraContextBuilder.cleanForPrompt('a\nb\t"c"   d', 80),
        "a b 'c' d");
    expect(AuroraContextBuilder.cleanForPrompt('x' * 300, 200), hasLength(200));
  });

  test('week totals from the ledger', () async {
    final ledger = XpLedgerService(db);
    final monday = DateTime(2026, 10, 26);
    await ledger.record(
        userId: 'u1', itemKey: 'h:a', xp: 120, category: 'health', type: 'habit', day: monday);
    await ledger.record(
        userId: 'u1', itemKey: 't:b', xp: 30, category: 'work', type: 'daily', day: monday);
    await ledger.record(
        userId: 'u1', itemKey: 't:c', xp: 40, category: 'work', type: 'daily', day: today);
    // Outside the 7 days.
    await ledger.record(
        userId: 'u1', itemKey: 't:d', xp: 999, category: 'work', type: 'daily',
        day: addDays(today, -10));
    final week = (await build())['week'] as Map;
    expect(week['xp'], 190);
    expect(week['tended_days'], 2);
    expect(week['best_day'], 'Monday');
    expect(week['by_category'], [
      {'category': 'health', 'xp': 120},
      {'category': 'work', 'xp': 70},
    ]);

    final month =
        await build(period: AuroraContextPeriod.month);
    expect(month.containsKey('week'), isFalse);
    expect((month['month'] as Map)['xp'], 190 + 999);
    expect((month['month'] as Map)['best_day'], dayKey(addDays(today, -10)));
  });

  test('moods: last 7 days, one per moment, notes capped', () async {
    final repo = CheckInRepository(CheckInDao(db), clock: () => now);
    for (var back = 0; back < 10; back++) {
      for (final m in CheckInMoment.values) {
        await repo.save(
            userId: 'u1',
            moment: m,
            mood: 4,
            note: back == 0 ? 'n' * 300 : 'good walk',
            day: addDays(today, -back));
      }
    }
    final moods = (await build())['moods'] as List;
    expect(moods, hasLength(14));
    expect((moods.first as Map)['date'], dayKey(addDays(today, -6)));
    expect((moods.first as Map)['moment'], 'morning');
    expect(((moods.last as Map)['note'] as String).length, 200);

    final month = (await build(period: AuroraContextPeriod.month))['moods'] as List;
    expect(month, hasLength(20));
  });

  test('memories only when premium, capped at 20 newest', () async {
    var t = DateTime(2026, 10, 1);
    final repo = AuroraMemoryRepository(AuroraMemoryDao(db), clock: () {
      t = t.add(const Duration(minutes: 1));
      return t;
    });
    for (var i = 0; i < 25; i++) {
      await repo.add('u1', 'Fact $i');
    }
    expect((await build()).containsKey('memories'), isFalse);
    final memories = (await build(premium: true))['memories'] as List;
    expect(memories, hasLength(20));
    expect(memories.first, 'Fact 24');
  });
}
