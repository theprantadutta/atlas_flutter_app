import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/progress_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/world_dao.dart';

void main() {
  late AtlasDatabase db;
  late TaskDao tasks;

  // Drift stores DateTimes with second precision by default.
  final t0 = DateTime(2026, 10, 15, 9, 0, 0);
  final t1 = DateTime(2026, 10, 15, 9, 0, 5);

  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    tasks = TaskDao(db);
  });

  tearDown(() => db.close());

  TasksCompanion task(String id, DateTime updatedAt) => TasksCompanion(
        id: Value(id),
        userId: const Value('u1'),
        title: Value('Task $id'),
        type: const Value('daily'),
        category: const Value('health'),
        createdAt: Value(t0),
        updatedAt: Value(updatedAt),
        isDirty: const Value(true),
      );

  test('markSynced clears dirty only when updatedAt still matches', () async {
    await tasks.upsertTask(task('a', t0));
    await tasks.upsertTask(task('b', t0));

    // Snapshot what the push sends...
    final pushed = {
      for (final t in await tasks.getDirtyTasks('u1')) t.id: t.updatedAt,
    };

    // ...then `b` is edited while the push is in flight.
    await tasks.updateFields(
      'b',
      TasksCompanion(title: const Value('edited'), updatedAt: Value(t1)),
    );

    final syncedAt = DateTime(2026, 10, 15, 9, 1);
    await tasks.markSynced(pushed, syncedAt);

    final a = await tasks.getTaskById('a');
    final b = await tasks.getTaskById('b');
    expect(a!.isDirty, isFalse);
    expect(a.lastSyncedAt, syncedAt);
    expect(b!.isDirty, isTrue, reason: 'edited mid-push, must go out again');
    expect(b.lastSyncedAt, isNull);
  });

  test('markSynced with an empty map is a no-op', () async {
    await tasks.upsertTask(task('a', t0));
    await tasks.markSynced(const {}, DateTime.now());
    expect((await tasks.getTaskById('a'))!.isDirty, isTrue);
  });

  test('getEntryForDay tolerates duplicate rows for one day', () async {
    final progress = ProgressDao(db);
    final day = DateTime(2026, 10, 15);
    for (final (id, updated) in [('p1', t0), ('p2', t1)]) {
      await progress.upsertProgress(ProgressEntriesCompanion(
        id: Value(id),
        userId: const Value('u1'),
        date: Value(day),
        createdAt: Value(t0),
        updatedAt: Value(updated),
      ));
    }
    final entry = await progress.getEntryForDay('u1', day);
    expect(entry?.id, 'p2', reason: 'most recently updated wins');
  });

  test('getTileByPosition tolerates duplicate rows for one cell', () async {
    final world = WorldDao(db);
    for (final (id, updated) in [('w1', t1), ('w2', t0)]) {
      await world.upsertTile(WorldTilesCompanion(
        id: Value(id),
        userId: const Value('u1'),
        name: const Value('Meadow'),
        tileType: const Value('grass'),
        positionX: const Value(2),
        positionY: const Value(3),
        createdAt: Value(t0),
        updatedAt: Value(updated),
      ));
    }
    final tile = await world.getTileByPosition('u1', 2, 3);
    expect(tile?.id, 'w1');
  });
}
