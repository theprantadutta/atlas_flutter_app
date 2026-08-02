import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:atlas_flutter_app/core/constants/app_constants.dart';
import 'package:atlas_flutter_app/data/database/tables/users_table.dart';
import 'package:atlas_flutter_app/data/database/tables/tasks_table.dart';
import 'package:atlas_flutter_app/data/database/tables/habits_table.dart';
import 'package:atlas_flutter_app/data/database/tables/goals_table.dart';
import 'package:atlas_flutter_app/data/database/tables/avatars_table.dart';
import 'package:atlas_flutter_app/data/database/tables/achievements_table.dart';
import 'package:atlas_flutter_app/data/database/tables/world_tiles_table.dart';
import 'package:atlas_flutter_app/data/database/tables/progress_entries_table.dart';
import 'package:atlas_flutter_app/data/database/tables/sync_operations_table.dart';
import 'package:atlas_flutter_app/data/database/tables/notifications_table.dart';
import 'package:atlas_flutter_app/data/database/tables/aurora_reflections_table.dart';
import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/habit_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/goal_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/avatar_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/achievement_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/world_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/progress_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/sync_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/notification_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/aurora_reflection_dao.dart';

part 'atlas_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Tasks,
    Habits,
    Goals,
    Avatars,
    Achievements,
    WorldTiles,
    ProgressEntries,
    SyncOperations,
    Notifications,
    AuroraReflections,
  ],
  daos: [
    TaskDao,
    HabitDao,
    GoalDao,
    AvatarDao,
    AchievementDao,
    WorldDao,
    ProgressDao,
    SyncDao,
    NotificationDao,
    AuroraReflectionDao,
  ],
)
class AtlasDatabase extends _$AtlasDatabase {
  AtlasDatabase() : super(_openConnection());

  /// Constructor for testing with a provided QueryExecutor.
  AtlasDatabase.forTesting(super.e);

  @override
  int get schemaVersion => AppConstants.databaseVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(notifications);
        }
        if (from < 3) {
          // Offline-first sync metadata on Tasks.
          await m.addColumn(tasks, tasks.isDirty);
          await m.addColumn(tasks, tasks.isDeleted);
          await m.addColumn(tasks, tasks.deletedAt);
          await m.addColumn(tasks, tasks.lastSyncedAt);
        }
        if (from < 4) {
          // Offline-first sync metadata on Habits.
          await m.addColumn(habits, habits.isDirty);
          await m.addColumn(habits, habits.isDeleted);
          await m.addColumn(habits, habits.deletedAt);
          await m.addColumn(habits, habits.lastSyncedAt);
        }
        if (from < 5) {
          // Offline-first sync metadata on Goals.
          await m.addColumn(goals, goals.isDirty);
          await m.addColumn(goals, goals.isDeleted);
          await m.addColumn(goals, goals.deletedAt);
          await m.addColumn(goals, goals.lastSyncedAt);
        }
        if (from < 6) {
          // Offline-first sync metadata on Avatars.
          await m.addColumn(avatars, avatars.isDirty);
          await m.addColumn(avatars, avatars.isDeleted);
          await m.addColumn(avatars, avatars.deletedAt);
          await m.addColumn(avatars, avatars.lastSyncedAt);
        }
        if (from < 7) {
          // Offline-first sync metadata on World tiles.
          await m.addColumn(worldTiles, worldTiles.isDirty);
          await m.addColumn(worldTiles, worldTiles.isDeleted);
          await m.addColumn(worldTiles, worldTiles.deletedAt);
          await m.addColumn(worldTiles, worldTiles.lastSyncedAt);
        }
        if (from < 8) {
          // Offline-first sync metadata on Achievements.
          await m.addColumn(achievements, achievements.isDirty);
          await m.addColumn(achievements, achievements.isDeleted);
          await m.addColumn(achievements, achievements.deletedAt);
          await m.addColumn(achievements, achievements.lastSyncedAt);
        }
        if (from < 9) {
          // Offline-first sync metadata on Progress entries.
          await m.addColumn(progressEntries, progressEntries.isDirty);
          await m.addColumn(progressEntries, progressEntries.isDeleted);
          await m.addColumn(progressEntries, progressEntries.deletedAt);
          await m.addColumn(progressEntries, progressEntries.lastSyncedAt);
        }
        if (from < 10) {
          // Offline-first sync metadata on Notifications (incl. updatedAt
          // for last-write-wins).
          await m.addColumn(notifications, notifications.updatedAt);
          await m.addColumn(notifications, notifications.isDirty);
          await m.addColumn(notifications, notifications.isDeleted);
          await m.addColumn(notifications, notifications.deletedAt);
          await m.addColumn(notifications, notifications.lastSyncedAt);
        }
        if (from < 11) {
          // Aurora reflection local cache.
          await m.createTable(auroraReflections);
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
        // Enable WAL mode for better performance
        await customStatement('PRAGMA journal_mode = WAL');
      },
    );
  }

  /// Deletes every row in every table, leaving an empty but valid schema.
  ///
  /// This is a *hard* wipe, not the soft-delete tombstoning the sync engine
  /// uses: it is for when the data must genuinely stop existing on this device
  /// — account deletion (App Store Guideline 5.1.1(v)) and switching accounts,
  /// where the next user must never see the previous one's world.
  ///
  /// Iterates [allTables] so a newly added table is covered automatically
  /// rather than silently surviving the wipe.
  Future<void> wipeAllLocalData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
