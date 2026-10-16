import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/services/xp_ledger_service.dart';

LedgerDay day(DateTime d, int xp, [Map<String, int> items = const {}]) => LedgerDay(
      date: d,
      xp: xp,
      count: items.length,
      items: Map.of(items),
      categories: const {},
      types: const {},
    );

void main() {
  final today = DateTime(2026, 10, 14); // a Wednesday

  group('days', () {
    test('ISO week and Monday start', () {
      expect(isoWeek(DateTime(2026, 1, 1)), 1);
      expect(isoWeek(DateTime(2026, 7, 30)), 31);
      expect(startOfWeek(today), DateTime(2026, 10, 12));
      expect(longDate(DateTime(2026, 10, 14)), 'Wednesday, 14 October');
      expect(dayRange(DateTime(2026, 7, 26), DateTime(2026, 8, 2)), '26 Jul to 2 Aug');
      expect(clockLabel(21, 0), '9:00 pm');
      expect(clockLabel(0, 5), '12:05 am');
    });
  });

  group('LevelInfo', () {
    test('uses the quadratic curve, not xp % 1000', () {
      final l = LevelInfo.of(640);
      expect(l.level, GamificationConstants.calculateLevel(640));
      expect(l.floor, GamificationConstants.xpRequiredForLevel(l.level));
      expect(l.ceil, GamificationConstants.xpRequiredForLevel(l.level + 1));
      expect(l.xpInLevel + l.floor, 640);
      expect(l.fraction, inInclusiveRange(0, 1));
    });

    test('level 1 starts at zero', () {
      final l = LevelInfo.of(0);
      expect(l.level, 1);
      expect(l.xpInLevel, 0);
      expect(l.xpForLevel, GamificationConstants.xpRequiredForLevel(2));
    });
  });

  group('LedgerMath', () {
    test('streak ends today, or yesterday when today is empty', () {
      final days = [
        day(addDays(today, -1), 20),
        day(addDays(today, -2), 10),
        day(addDays(today, -4), 10),
      ];
      expect(LedgerMath.currentStreak(days, today), 2);
      expect(LedgerMath.currentStreak([day(today, 5), ...days], today), 3);
      expect(LedgerMath.currentStreak(days, addDays(today, 2)), 0);
      expect(LedgerMath.longestStreak(days), 2);
    });

    test('last7 reads item keys per day, oldest first', () {
      final days = [
        day(today, 10, {'h:a': 10}),
        day(addDays(today, -6), 10, {'h:a': 10}),
        day(addDays(today, -3), 10, {'h:b': 10}),
      ];
      expect(LedgerMath.last7(days, 'h:a', today),
          [true, false, false, false, false, false, true]);
      expect(LedgerMath.lastCompletionBefore(days, 'h:a', today), addDays(today, -6));
    });
  });

  group('HabitSchedule', () {
    test('daily streak continues from yesterday and restarts after a gap', () {
      expect(HabitSchedule.nextStreak('daily', addDays(today, -1), 4, today), 5);
      expect(HabitSchedule.nextStreak('daily', addDays(today, -2), 4, today), 1);
      expect(HabitSchedule.nextStreak('daily', today, 4, today), 4);
    });

    test('weekday habits skip the weekend', () {
      final monday = DateTime(2026, 10, 12);
      final friday = DateTime(2026, 10, 9);
      expect(HabitSchedule.streakAlive('weekdays', friday, monday), isTrue);
      expect(HabitSchedule.nextStreak('weekdays', friday, 3, monday), 4);
    });

    test('weekly habits are done for the whole ISO week', () {
      final monday = DateTime(2026, 10, 12);
      expect(HabitSchedule.doneInPeriod('weekly', monday, today), isTrue);
      expect(HabitSchedule.doneInPeriod('weekly', addDays(monday, -1), today), isFalse);
      expect(HabitSchedule.nextStreak('weekly', addDays(monday, -3), 2, today), 3);
    });

    test('daily tasks come back the next day, long-term ones stay done', () {
      expect(TaskSchedule.doneInPeriod('daily', addDays(today, -1), today), isFalse);
      expect(TaskSchedule.doneInPeriod('weekly', addDays(today, -1), today), isTrue);
      expect(TaskSchedule.doneInPeriod('longTerm', DateTime(2020), today), isTrue);
    });
  });

  group('XpLedgerService', () {
    late AtlasDatabase db;
    late XpLedgerService ledger;
    setUp(() {
      db = AtlasDatabase.forTesting(NativeDatabase.memory());
      ledger = XpLedgerService(db);
    });
    tearDown(() => db.close());

    Future<List<ProgressEntry>> rows() => db.select(db.progressEntries).get();

    test('records once per item per day, with a deterministic id', () async {
      await ledger.record(userId: 'u', itemKey: 'h:a', xp: 10, category: 'health', type: 'habit', day: today);
      await ledger.record(userId: 'u', itemKey: 'h:a', xp: 10, category: 'health', type: 'habit', day: today);
      await ledger.record(userId: 'u', itemKey: 't:b', xp: 25, category: 'work', type: 'daily', day: today);
      final r = await rows();
      expect(r, hasLength(1));
      expect(r.single.id, Ledger.entryId('u', today));
      expect(r.single.xpGained, 35);
      expect(r.single.tasksCompleted, 2);
      final parsed = LedgerDay.parse(
        date: r.single.date,
        xp: r.single.xpGained,
        count: r.single.tasksCompleted,
        categoryBreakdown: r.single.categoryBreakdown,
        taskTypeBreakdown: r.single.taskTypeBreakdown,
        additionalMetrics: r.single.additionalMetrics,
      );
      expect(parsed.items, {'h:a': 10, 't:b': 25});
      expect(parsed.categories, {'health': 10, 'work': 25});
      expect(parsed.types, {'habit': 1, 'daily': 1});
    });

    test('revoke reverses exactly and is a no-op twice', () async {
      await ledger.record(userId: 'u', itemKey: 'h:a', xp: 10, category: 'health', type: 'habit', day: today);
      await ledger.record(userId: 'u', itemKey: 't:b', xp: 25, category: 'work', type: 'daily', day: today);
      expect(await ledger.revoke(userId: 'u', itemKey: 't:b', category: 'work', type: 'daily', day: today), 25);
      expect(await ledger.revoke(userId: 'u', itemKey: 't:b', category: 'work', type: 'daily', day: today), 0);
      final r = (await rows()).single;
      expect(r.xpGained, 10);
      expect(r.tasksCompleted, 1);
      expect(LedgerDay.decodeIntMap(r.categoryBreakdown), {'health': 10});
    });

    test('adopts an existing legacy row for the day instead of duplicating', () async {
      final now = DateTime.now();
      await db.into(db.progressEntries).insert(ProgressEntriesCompanion.insert(
            id: 'legacy-row',
            userId: 'u',
            date: today,
            xpGained: const Value(40),
            createdAt: now,
            updatedAt: now,
          ));
      await ledger.record(userId: 'u', itemKey: 'h:a', xp: 10, category: 'health', type: 'habit', day: today);
      final r = await rows();
      expect(r, hasLength(1));
      expect(r.single.xpGained, 50);
    });
  });
}
