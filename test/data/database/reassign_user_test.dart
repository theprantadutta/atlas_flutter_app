import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/models/user.dart' as model;

void main() {
  late AtlasDatabase db;
  late TaskDao tasks;
  final t0 = DateTime(2026, 11, 24, 9);

  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    tasks = TaskDao(db);
  });

  tearDown(() => db.close());

  TasksCompanion task(String id, String userId) => TasksCompanion(
        id: Value(id),
        userId: Value(userId),
        title: Value('Task $id'),
        type: const Value('daily'),
        category: const Value('health'),
        createdAt: Value(t0),
        updatedAt: Value(t0),
        isDirty: const Value(false),
      );

  test('a guest’s rows move to the account, marked to sync, and nobody else’s do', () async {
    final guest = '${model.User.guestIdPrefix}abc';
    await tasks.upsertTask(task('mine', guest));
    await tasks.upsertTask(task('theirs', 'someone-else'));

    final moved = await db.reassignUser(guest, 'acct-1');

    expect(moved, 1);
    final mine = await tasks.getTaskById('mine');
    expect(mine!.userId, 'acct-1');
    expect(mine.isDirty, isTrue, reason: 'uploads if the account has sync');
    expect(mine.updatedAt.isAfter(t0), isTrue);
    final theirs = await tasks.getTaskById('theirs');
    expect(theirs!.userId, 'someone-else');
    expect(theirs.isDirty, isFalse);
  });

  test('moving to the same id changes nothing', () async {
    await tasks.upsertTask(task('a', 'u1'));
    expect(await db.reassignUser('u1', 'u1'), 0);
  });

  test('a guest is recognised by the id prefix', () {
    expect(model.User.guest('${model.User.guestIdPrefix}x').isGuest, isTrue);
    expect(model.User(id: 'acct', email: 'a@b.c', fullName: 'A', createdAt: t0).isGuest, isFalse);
  });
}
