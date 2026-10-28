import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/check_in_dao.dart';
import 'package:atlas_flutter_app/data/services/offline_manager.dart';
import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';
import 'package:atlas_flutter_app/features/check_in/providers/check_in_providers.dart';

void main() {
  late AtlasDatabase db;
  late CheckInDao dao;
  late CheckInRepository repo;
  var now = DateTime(2026, 10, 28, 9, 15);

  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    dao = CheckInDao(db);
    now = DateTime(2026, 10, 28, 9, 15);
    repo = CheckInRepository(dao, clock: () => now);
  });

  tearDown(() => db.close());

  Future<List<CheckIn>> all() => db.select(db.checkIns).get();

  test('one row per day and moment: saving again updates it', () async {
    final first = await repo.save(
        userId: 'u1', moment: CheckInMoment.morning, mood: 2, note: 'tired');
    now = now.add(const Duration(minutes: 5));
    final second = await repo.save(
        userId: 'u1', moment: CheckInMoment.morning, mood: 4, note: 'better');

    expect(second.id, first.id);
    final rows = await all();
    expect(rows, hasLength(1));
    expect(rows.single.mood, 4);
    expect(rows.single.note, 'better');
    expect(rows.single.date, DateTime(2026, 10, 28));

    // Evening and another day are separate rows.
    await repo.save(userId: 'u1', moment: CheckInMoment.evening, mood: 3);
    await repo.save(
        userId: 'u1',
        moment: CheckInMoment.morning,
        mood: 3,
        day: DateTime(2026, 10, 27));
    expect(await all(), hasLength(3));
  });

  test('writes are dirty for sync; mood is clamped and notes capped', () async {
    final row = await repo.save(
        userId: 'u1',
        moment: CheckInMoment.evening,
        mood: 9,
        note: '  ${'a' * 250}  ');
    expect(row.isDirty, isTrue);
    expect(row.mood, 5);
    expect(row.note!.length, 200);

    await dao.markSynced({row.id: row.updatedAt}, now);
    expect((await repo.getById(row.id))!.isDirty, isFalse);

    now = now.add(const Duration(seconds: 2));
    await repo.setReply(row.id, 'That sounds like a full day.');
    final replied = (await repo.getById(row.id))!;
    expect(replied.auroraReply, 'That sounds like a full day.');
    expect(replied.isDirty, isTrue);
  });

  test('a changed mood clears the old reply; the same one keeps it', () async {
    final row =
        await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 3);
    await repo.setReply(row.id, 'Okay is okay.');
    final same =
        await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 3);
    expect(same.auroraReply, 'Okay is okay.');
    final changed =
        await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 5);
    expect(changed.auroraReply, isNull);
  });

  test('delete leaves a dirty tombstone; saving again revives it', () async {
    final row =
        await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 3);
    now = now.add(const Duration(seconds: 2));
    await repo.delete(row.id);

    final tomb = (await repo.getById(row.id))!;
    expect(tomb.isDeleted, isTrue);
    expect(tomb.deletedAt, isNotNull);
    expect(tomb.isDirty, isTrue);
    expect(await repo.forMoment('u1', now, CheckInMoment.morning), isNull);
    expect(await repo.getRange('u1', DateTime(2026, 10, 28), DateTime(2026, 10, 29)),
        isEmpty);

    now = now.add(const Duration(seconds: 2));
    final again =
        await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 4);
    expect(again.id, row.id);
    expect(again.isDeleted, isFalse);
    expect(again.deletedAt, isNull);
    expect(await all(), hasLength(1));
  });

  test('watchDay streams today, morning first', () async {
    await repo.save(userId: 'u1', moment: CheckInMoment.evening, mood: 4);
    await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 2);
    await repo.save(userId: 'u2', moment: CheckInMoment.morning, mood: 1);
    final today = await repo.watchDay('u1', now).first;
    expect(today.map((c) => c.moment), ['morning', 'evening']);
  });

  group('pull merge', () {
    Map<String, dynamic> remote(String id, DateTime updated,
            {int mood = 4, String moment = 'morning', bool deleted = false}) =>
        {
          'id': id,
          'user_id': 'u1',
          'date': DateTime(2026, 10, 28).toUtc().toIso8601String(),
          'moment': moment,
          'mood': mood,
          'note': null,
          'aurora_reply': null,
          'is_deleted': deleted,
          'created_at': updated.toUtc().toIso8601String(),
          'updated_at': updated.toUtc().toIso8601String(),
        };

    test('wire round trip', () async {
      final row = await repo.save(
          userId: 'u1', moment: CheckInMoment.evening, mood: 2, note: 'long day');
      final wire = OfflineManager.checkInWire(row);
      expect(wire.keys, containsAll([
        'id', 'user_id', 'date', 'moment', 'mood', 'note', 'aurora_reply',
        'is_deleted', 'deleted_at', 'created_at', 'updated_at',
      ]));
      await dao.hardDelete(row.id);
      await OfflineManager.applyRemoteCheckIn(dao, 'u1', wire);
      final back = (await repo.getById(row.id))!;
      expect(back.date, row.date);
      expect(back.moment, 'evening');
      expect(back.note, 'long day');
      expect(back.isDirty, isFalse);
    });

    test('local wins ties; a strictly newer server copy wins', () async {
      final row =
          await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 2);
      await OfflineManager.applyRemoteCheckIn(
          dao, 'u1', {...remote(row.id, row.updatedAt, mood: 5)});
      expect((await repo.getById(row.id))!.mood, 2);

      await OfflineManager.applyRemoteCheckIn(dao, 'u1',
          remote(row.id, row.updatedAt.add(const Duration(seconds: 1)), mood: 5));
      expect((await repo.getById(row.id))!.mood, 5);
    });

    test('a newer tombstone removes the local row', () async {
      final row =
          await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 2);
      await OfflineManager.applyRemoteCheckIn(dao, 'u1',
          remote(row.id, row.updatedAt.add(const Duration(seconds: 1)), deleted: true));
      expect(await repo.getById(row.id), isNull);
    });

    test('same slot, different id: the newer winner replaces the local row',
        () async {
      final mine =
          await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 2);
      final later = mine.updatedAt.add(const Duration(minutes: 1));
      // The server tombstones my older row and sends the winner.
      await OfflineManager.applyRemoteCheckIn(
          dao, 'u1', remote(mine.id, later, deleted: true));
      await OfflineManager.applyRemoteCheckIn(
          dao, 'u1', remote('theirs', later, mood: 5));
      final rows = await all();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'theirs');
      expect(rows.single.mood, 5);
    });

    test('same slot, different id, winner first: still one row', () async {
      final mine =
          await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 2);
      final later = mine.updatedAt.add(const Duration(minutes: 1));
      await OfflineManager.applyRemoteCheckIn(
          dao, 'u1', remote('theirs', later, mood: 5));
      await OfflineManager.applyRemoteCheckIn(
          dao, 'u1', remote(mine.id, later, deleted: true));
      final rows = await all();
      expect(rows.map((r) => r.id), ['theirs']);
    });

    test('same slot, older remote: the local row wins and stays dirty',
        () async {
      final mine =
          await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 2);
      await OfflineManager.applyRemoteCheckIn(dao, 'u1',
          remote('theirs', mine.updatedAt.subtract(const Duration(minutes: 1))));
      final rows = await all();
      expect(rows.map((r) => r.id), [mine.id]);
      expect(rows.single.isDirty, isTrue);
    });
  });

  group('when the card shows', () {
    test('morning before noon, evening from 17:00, hidden between', () {
      expect(dueCheckInMoment(DateTime(2026, 10, 28, 7), done: {}),
          CheckInMoment.morning);
      expect(dueCheckInMoment(DateTime(2026, 10, 28, 13), done: {}), isNull);
      expect(dueCheckInMoment(DateTime(2026, 10, 28, 17), done: {}),
          CheckInMoment.evening);
    });

    test('hidden once done or dismissed', () {
      expect(
          dueCheckInMoment(DateTime(2026, 10, 28, 7),
              done: {CheckInMoment.morning}),
          isNull);
      expect(
          dueCheckInMoment(DateTime(2026, 10, 28, 20),
              done: {CheckInMoment.morning},
              dismissed: {CheckInMoment.evening}),
          isNull);
    });

    test('mood strip has one slot per day, empty without a check-in', () async {
      await repo.save(
          userId: 'u1',
          moment: CheckInMoment.morning,
          mood: 2,
          day: DateTime(2026, 10, 26));
      await repo.save(
          userId: 'u1',
          moment: CheckInMoment.evening,
          mood: 4,
          day: DateTime(2026, 10, 26));
      await repo.save(userId: 'u1', moment: CheckInMoment.morning, mood: 5);
      final start = DateTime(2026, 10, 22);
      final rows = await repo.getRange('u1', start, DateTime(2026, 10, 29));
      expect(moodStrip(rows, start, 7), [null, null, null, null, 4, null, 5]);
    });
  });
}
