import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/achievement_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/avatar_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/goal_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/habit_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/notification_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/progress_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/world_dao.dart';
import 'package:atlas_flutter_app/data/repositories/sync_repository.dart';
import 'package:atlas_flutter_app/data/services/conflict_resolution_service.dart';
import 'package:atlas_flutter_app/data/services/offline_manager.dart';

/// Never reached: every test here stops before a sync can run, because
/// [SyncConfig.enabled] is false in a test build. The cursor is restored by
/// `setAuthenticated`, which is the part under test.
class _UnusedSyncRepository implements SyncRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('the network must not be touched in these tests');
}

/// Which account the pull cursor belongs to.
///
/// The cursor lives in SharedPreferences rather than the Drift database, so
/// wiping local data does not clear it. It used to be one global key, which
/// meant a second account signing in on the same device inherited the first
/// account's cursor: `/sync/pull` asked for everything changed *since* that
/// moment, the server correctly returned nothing older, and a fully populated
/// account came up empty — permanently, because a cursor only moves forward.
void main() {
  late AtlasDatabase db;
  late OfflineManager manager;

  OfflineManager build() => OfflineManager(
        taskDao: TaskDao(db),
        habitDao: HabitDao(db),
        goalDao: GoalDao(db),
        avatarDao: AvatarDao(db),
        worldDao: WorldDao(db),
        achievementDao: AchievementDao(db),
        progressDao: ProgressDao(db),
        notificationDao: NotificationDao(db),
        syncRepository: _UnusedSyncRepository(),
        conflictResolution: ConflictResolutionService(),
      );

  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    manager = build();
  });

  tearDown(() => db.close());

  /// setAuthenticated restores the cursor asynchronously, before syncing.
  Future<void> signIn(String userId) async {
    manager.setAuthenticated(true, userId: userId);
    await Future<void>.delayed(Duration.zero);
  }

  test('a second account does not inherit the first account cursor', () async {
    final aSyncedAt = DateTime.now().subtract(const Duration(minutes: 5));
    SharedPreferences.setMockInitialValues({
      'offline_manager_last_sync_user-a': aSyncedAt.toIso8601String(),
    });

    await signIn('user-a');
    expect(manager.lastSyncTime, isNotNull,
        reason: 'user-a keeps their own cursor');

    await signIn('user-b');
    expect(manager.lastSyncTime, isNull,
        reason: 'user-b has never synced here, so this must be a full pull');
  });

  test('each account keeps its own cursor', () async {
    final aSyncedAt = DateTime.parse('2026-09-18T06:49:14Z');
    final bSyncedAt = DateTime.parse('2026-01-02T03:04:05Z');
    SharedPreferences.setMockInitialValues({
      'offline_manager_last_sync_user-a': aSyncedAt.toIso8601String(),
      'offline_manager_last_sync_user-b': bSyncedAt.toIso8601String(),
    });

    await signIn('user-a');
    expect(manager.lastSyncTime, aSyncedAt);

    await signIn('user-b');
    expect(manager.lastSyncTime, bSyncedAt);

    await signIn('user-a');
    expect(manager.lastSyncTime, aSyncedAt, reason: 'and survives a round trip');
  });

  test('signing out drops the cursor', () async {
    SharedPreferences.setMockInitialValues({
      'offline_manager_last_sync_user-a': DateTime.now().toIso8601String(),
    });
    await signIn('user-a');
    expect(manager.lastSyncTime, isNotNull);

    manager.setAuthenticated(false);
    expect(manager.lastSyncTime, isNull,
        reason: 'a signed-out manager must not hold the last user cursor');
  });

  test('an upgrading install keeps its cursor, once', () async {
    final legacy = DateTime.parse('2026-09-01T10:00:00Z');
    SharedPreferences.setMockInitialValues({
      'offline_manager_last_sync': legacy.toIso8601String(),
    });

    // The first account to sign in after the upgrade may claim it, so an
    // existing user does not re-pull their whole history.
    await signIn('user-a');
    expect(manager.lastSyncTime, legacy);

    // But it is consumed, so it can never be handed to anyone else.
    manager = build();
    await signIn('user-b');
    expect(manager.lastSyncTime, isNull);
  });
}
