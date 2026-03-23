import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

import 'package:atlas_flutter_app/data/repositories/task_repository.dart';
import 'package:atlas_flutter_app/data/repositories/habit_repository.dart';
import 'package:atlas_flutter_app/data/repositories/goal_repository.dart';
import 'package:atlas_flutter_app/data/repositories/avatar_repository.dart';
import 'package:atlas_flutter_app/data/repositories/achievement_repository.dart';
import 'package:atlas_flutter_app/data/repositories/world_repository.dart';
import 'package:atlas_flutter_app/data/repositories/progress_repository.dart';
import 'package:atlas_flutter_app/data/repositories/analytics_repository.dart';
import 'package:atlas_flutter_app/data/repositories/sync_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.read(apiServiceProvider));
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(ref.read(apiServiceProvider));
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.read(apiServiceProvider));
});

final avatarRepositoryProvider = Provider<AvatarRepository>((ref) {
  return AvatarRepository(ref.read(apiServiceProvider));
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(ref.read(apiServiceProvider));
});

final worldRepositoryProvider = Provider<WorldRepository>((ref) {
  return WorldRepository(ref.read(apiServiceProvider));
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.read(apiServiceProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.read(apiServiceProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(ref.read(apiServiceProvider));
});
