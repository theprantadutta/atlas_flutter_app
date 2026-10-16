import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/starter_seeder.dart';

final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

void main() {
  late AtlasDatabase db;
  late StarterSeeder seeder;
  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    seeder = StarterSeeder(db);
  });
  tearDown(() => db.close());

  Future<int> liveHabits(String user) async =>
      (await (db.select(db.habits)..where((h) => h.userId.equals(user) & h.isDeleted.equals(false))).get())
          .length;
  Future<int> ledgerXp(String user) async =>
      (await (db.select(db.progressEntries)..where((p) => p.userId.equals(user))).get())
          .fold<int>(0, (a, p) => a + p.xpGained);

  test('seeds UUID rows with a ledger history, scoped to the user', () async {
    await seeder.seed('a');
    final habits = await db.select(db.habits).get();
    expect(habits, hasLength(5));
    expect(habits.every((h) => _uuid.hasMatch(h.id) && h.userId == 'a'), isTrue);
    final xp = await ledgerXp('a');
    expect(xp, greaterThan(1000));
    // One ledger row per day, with deterministic ids.
    final rows = await db.select(db.progressEntries).get();
    expect(rows.every((r) => r.id == Ledger.entryId('a', r.date)), isTrue);
    expect(await seeder.hasSeed('a'), isTrue);
    expect(await seeder.hasSeed('b'), isFalse);
  });

  test('two users on one device do not collide', () async {
    await seeder.seed('a');
    await seeder.seed('b');
    expect(await liveHabits('a'), 5);
    expect(await liveHabits('b'), 5);
  });

  test('remove takes back exactly the seeded history, and re-adding revives', () async {
    await seeder.seed('a');
    // A real completion today, which removal must keep.
    final today = dateOnly(DateTime.now());
    final row = await (db.select(db.progressEntries)
          ..where((p) => p.id.equals(Ledger.entryId('a', today))))
        .getSingle();
    final items = LedgerDay.decodeIntMap(row.additionalMetrics)..['t:real'] = 25;
    await (db.update(db.progressEntries)..where((p) => p.id.equals(row.id))).write(
      ProgressEntriesCompanion(
        xpGained: Value(row.xpGained + 25),
        tasksCompleted: Value(row.tasksCompleted + 1),
        additionalMetrics: Value(LedgerDay.encode(items)),
      ),
    );

    await seeder.remove('a');
    expect(await liveHabits('a'), 0);
    expect(await seeder.hasSeed('a'), isFalse);
    expect(await ledgerXp('a'), 25);

    await seeder.seed('a');
    expect(await liveHabits('a'), 5);
    expect(await seeder.hasSeed('a'), isTrue);
  });

  test('legacy seed-* ids get proper ids once', () async {
    final now = DateTime.now();
    await db.into(db.tasks).insert(TasksCompanion.insert(
          id: 'seed-task-0',
          userId: 'a',
          title: 'Old',
          type: 'daily',
          category: 'work',
          createdAt: now,
          updatedAt: now,
        ));
    await db.into(db.progressEntries).insert(ProgressEntriesCompanion.insert(
          id: 'seed-progress-0',
          userId: 'a',
          date: dateOnly(now),
          xpGained: const Value(40),
          createdAt: now,
          updatedAt: now,
        ));
    await seeder.migrateLegacyIds('a');
    final task = (await db.select(db.tasks).get()).single;
    expect(_uuid.hasMatch(task.id), isTrue);
    expect(task.isDirty, isTrue);
    final p = (await db.select(db.progressEntries).get()).single;
    expect(p.id, Ledger.entryId('a', dateOnly(now)));
    expect(p.xpGained, 40);
  });
}
