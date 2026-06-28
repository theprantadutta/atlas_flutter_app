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
import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/habit_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/goal_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/avatar_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/achievement_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/world_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/progress_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/sync_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/notification_dao.dart';

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
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
        // Enable WAL mode for better performance
        await customStatement('PRAGMA journal_mode = WAL');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
