import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/check_in_dao.dart';
import 'package:atlas_flutter_app/data/services/xp_ledger_service.dart';
import 'package:atlas_flutter_app/features/aurora/data/year_in_review.dart';
import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';

void main() {
  late AtlasDatabase db;
  late XpLedgerService ledger;
  final created = DateTime(2026, 1, 1);

  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    ledger = XpLedgerService(db);
  });

  tearDown(() => db.close());

  Future<void> habit(String id, String title) =>
      db.into(db.habits).insert(HabitsCompanion.insert(
            id: id,
            userId: 'u1',
            title: title,
            category: 'health',
            frequency: 'daily',
            createdAt: created,
            updatedAt: created,
          ));

  Future<void> tend(String key, int xp, DateTime day) => ledger.record(
      userId: 'u1', itemKey: key, xp: xp, category: 'health', type: 'habit', day: day);

  test('an empty year', () async {
    final y = await YearInReview.compute(db, 'u1', 2026);
    expect(y.isEmpty, isTrue);
    expect(y.bestMonth, isNull);
    expect(y.topHabits, isEmpty);
    expect(y.hasMoods, isFalse);
  });

  test('the numbers', () async {
    await habit('run', 'Morning run');
    await habit('read', 'Read');
    await habit('tea', 'Tea');
    await habit('walk', 'Walk');

    // March: 3 days in a row of runs (30 xp each) + reading on 2 of them.
    for (var d = 1; d <= 3; d++) {
      await tend('h:run', 30, DateTime(2026, 3, d));
    }
    await tend('h:read', 10, DateTime(2026, 3, 1));
    await tend('h:read', 10, DateTime(2026, 3, 2));
    // July: one big day, tea + walk.
    await tend('h:tea', 100, DateTime(2026, 7, 10));
    await tend('h:walk', 5, DateTime(2026, 7, 10));
    await tend('h:run', 30, DateTime(2026, 7, 12));
    // Last year and next year don't count.
    await tend('h:tea', 500, DateTime(2025, 12, 31));
    await tend('h:tea', 500, DateTime(2027, 1, 1));

    // Places: 2 unlocked this year, 1 last year, 1 locked.
    Future<void> tile(String id, DateTime? unlockedAt, {bool unlocked = true}) =>
        db.into(db.worldTiles).insert(WorldTilesCompanion.insert(
              id: id,
              userId: 'u1',
              name: id,
              tileType: 'grass',
              isUnlocked: Value(unlocked),
              unlockedAt: Value(unlockedAt),
              positionX: Value(id.hashCode % 100),
              createdAt: created,
              updatedAt: created,
            ));
    await tile('a', DateTime(2026, 2, 1));
    await tile('b', DateTime(2026, 8, 1));
    await tile('c', DateTime(2025, 6, 1));
    await tile('d', null, unlocked: false);

    final repo = CheckInRepository(CheckInDao(db));
    await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 4, day: DateTime(2026, 3, 1));
    await repo.save(userId: 'u1', moment: CheckInMoment.evening, mood: 4, day: DateTime(2026, 3, 1));
    await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 2, day: DateTime(2026, 3, 2));

    final y = await YearInReview.compute(db, 'u1', 2026);
    expect(y.daysTended, 5);
    expect(y.totalXp, 90 + 20 + 105 + 30);
    expect(y.longestStreak, 3);
    expect(y.topHabits.map((h) => h.title), ['Morning run', 'Read', 'Tea']);
    expect(y.topHabits.first.completions, 4);
    expect(y.bestMonth, 7); // 135 in July vs 110 in March
    expect(y.bestMonthXp, 135);
    expect(y.placesDiscovered, 2);
    expect(y.moodSplit, {4: 2, 2: 1});
  });

  test('in season from December 1st', () {
    expect(YearInReview.inSeason(DateTime(2026, 11, 30)), isFalse);
    expect(YearInReview.inSeason(DateTime(2026, 12, 1)), isTrue);
    expect(dayKey(DateTime(2026, 12, 1)), '2026-12-01');
  });
}
