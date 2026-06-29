import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/habit_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/goal_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/avatar_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/achievement_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/world_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/progress_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/sync_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/notification_dao.dart';
import 'package:atlas_flutter_app/data/services/conflict_resolution_service.dart';
import 'package:atlas_flutter_app/data/services/offline_manager.dart';

import 'package:atlas_flutter_app/data/repositories/task_repository.dart';
import 'package:atlas_flutter_app/data/repositories/habit_repository.dart';
import 'package:atlas_flutter_app/data/repositories/goal_repository.dart';
import 'package:atlas_flutter_app/data/repositories/avatar_repository.dart';
import 'package:atlas_flutter_app/data/repositories/achievement_repository.dart';
import 'package:atlas_flutter_app/data/repositories/world_repository.dart';
import 'package:atlas_flutter_app/data/repositories/progress_repository.dart';
import 'package:atlas_flutter_app/data/repositories/analytics_repository.dart';
import 'package:atlas_flutter_app/data/repositories/notification_repository.dart';
import 'package:atlas_flutter_app/data/repositories/sync_repository.dart';

// ─── DAO Providers ─────────────────────────────────────────────

final taskDaoProvider = Provider<TaskDao>((ref) {
  return TaskDao(ref.read(databaseProvider));
});

final habitDaoProvider = Provider<HabitDao>((ref) {
  return HabitDao(ref.read(databaseProvider));
});

final goalDaoProvider = Provider<GoalDao>((ref) {
  return GoalDao(ref.read(databaseProvider));
});

final avatarDaoProvider = Provider<AvatarDao>((ref) {
  return AvatarDao(ref.read(databaseProvider));
});

final achievementDaoProvider = Provider<AchievementDao>((ref) {
  return AchievementDao(ref.read(databaseProvider));
});

final worldDaoProvider = Provider<WorldDao>((ref) {
  return WorldDao(ref.read(databaseProvider));
});

final progressDaoProvider = Provider<ProgressDao>((ref) {
  return ProgressDao(ref.read(databaseProvider));
});

final syncDaoProvider = Provider<SyncDao>((ref) {
  return SyncDao(ref.read(databaseProvider));
});

final notificationDaoProvider = Provider<NotificationDao>((ref) {
  return NotificationDao(ref.read(databaseProvider));
});

// ─── Sync Infrastructure ───────────────────────────────────────

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(ref.read(apiServiceProvider));
});

final conflictResolutionServiceProvider =
    Provider<ConflictResolutionService>((ref) {
  return ConflictResolutionService();
});

final offlineManagerProvider = Provider<OfflineManager>((ref) {
  return OfflineManager(
    syncDao: ref.read(syncDaoProvider),
    taskDao: ref.read(taskDaoProvider),
    habitDao: ref.read(habitDaoProvider),
    goalDao: ref.read(goalDaoProvider),
    avatarDao: ref.read(avatarDaoProvider),
    worldDao: ref.read(worldDaoProvider),
    achievementDao: ref.read(achievementDaoProvider),
    syncRepository: ref.read(syncRepositoryProvider),
    conflictResolution: ref.read(conflictResolutionServiceProvider),
  );
});

// ─── Repository Providers ──────────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.read(apiServiceProvider),
    ref.read(offlineManagerProvider),
    ref.read(taskDaoProvider),
  );
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(
    ref.read(apiServiceProvider),
    ref.read(offlineManagerProvider),
    ref.read(habitDaoProvider),
  );
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(
    ref.read(apiServiceProvider),
    ref.read(offlineManagerProvider),
    ref.read(goalDaoProvider),
  );
});

final avatarRepositoryProvider = Provider<AvatarRepository>((ref) {
  return AvatarRepository(
    ref.read(apiServiceProvider),
    ref.read(offlineManagerProvider),
    ref.read(avatarDaoProvider),
  );
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(
    ref.read(apiServiceProvider),
    ref.read(offlineManagerProvider),
    ref.read(achievementDaoProvider),
  );
});

final worldRepositoryProvider = Provider<WorldRepository>((ref) {
  return WorldRepository(
    ref.read(apiServiceProvider),
    ref.read(offlineManagerProvider),
    ref.read(worldDaoProvider),
  );
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(
    ref.read(apiServiceProvider),
    ref.read(offlineManagerProvider),
    ref.read(progressDaoProvider),
  );
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(
    ref.read(apiServiceProvider),
    ref.read(offlineManagerProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    ref.read(apiServiceProvider),
    ref.read(offlineManagerProvider),
    ref.read(notificationDaoProvider),
  );
});
