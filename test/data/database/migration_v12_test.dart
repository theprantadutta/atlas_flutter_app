import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/constants/app_constants.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';

/// Upgrading a schema 11 database (before the Aurora companion) to 12 adds the
/// check-ins, conversation, message and memory tables plus the letter period,
/// and keeps existing rows.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('atlas_migration_');
    file = File('${dir.path}/atlas.db');
  });

  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {/* Windows may hold the WAL files briefly */}
  });

  Future<Set<String>> tables(AtlasDatabase db) async => {
        for (final r in await db
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
            .get())
          r.read<String>('name'),
      };

  Future<Set<String>> columns(AtlasDatabase db, String table) async => {
        for (final r in await db
            .customSelect("SELECT name FROM pragma_table_info('$table')")
            .get())
          r.read<String>('name'),
      };

  test('schema version is 12', () {
    expect(AppConstants.databaseVersion, 12);
  });

  test('11 to 12 adds the companion tables and keeps data', () async {
    // Build a database as schema 11 looked: current schema minus what 12 adds.
    var db = AtlasDatabase.forTesting(NativeDatabase(file));
    await db.customStatement('SELECT 1'); // opens and creates everything
    for (final t in [
      'aurora_messages',
      'aurora_conversations',
      'aurora_memories',
      'check_ins',
    ]) {
      await db.customStatement('DROP TABLE $t');
    }
    await db.customStatement('ALTER TABLE aurora_reflections DROP COLUMN period');
    await db.into(db.tasks).insert(TasksCompanion.insert(
          id: 't1',
          userId: 'u1',
          title: 'Call mum',
          type: 'daily',
          category: 'social',
          createdAt: DateTime(2026, 10, 1),
          updatedAt: DateTime(2026, 10, 1),
        ));
    await db.customStatement(
        "INSERT INTO aurora_reflections (id, user_id, content, period_start, "
        "period_end, model_tier, created_at) VALUES ('r1', 'u1', 'Dear you', 0, 0, 'free', 0)");
    await db.customStatement('PRAGMA user_version = 11');
    expect(await columns(db, 'aurora_reflections'), isNot(contains('period')));
    await db.close();

    // Reopen: the migrator runs from 11.
    db = AtlasDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    final names = await tables(db);
    expect(
        names,
        containsAll([
          'check_ins',
          'aurora_conversations',
          'aurora_messages',
          'aurora_memories',
        ]));
    expect(
        await columns(db, 'check_ins'),
        containsAll([
          'id', 'user_id', 'date', 'moment', 'mood', 'note', 'aurora_reply',
          'created_at', 'updated_at', 'is_dirty', 'is_deleted', 'deleted_at',
          'last_synced_at',
        ]));
    expect(await columns(db, 'aurora_memories'), contains('text'));

    // Existing rows survive; the old letter is a weekly one.
    expect((await db.select(db.tasks).get()).single.title, 'Call mum');
    final letter = await db.select(db.auroraReflections).getSingle();
    expect(letter.period, 'week');
    final version =
        await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 12);
  });

  test('a fresh database has the companion tables', () async {
    final db = AtlasDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(
        await tables(db),
        containsAll([
          'check_ins',
          'aurora_conversations',
          'aurora_messages',
          'aurora_memories',
        ]));
    expect(await columns(db, 'aurora_reflections'), contains('period'));
  });
}
