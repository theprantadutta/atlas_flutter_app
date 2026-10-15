import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/goal_dao.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;

/// Reactive stream of the current user's goals from Drift (source of truth).
final goalsStreamProvider = StreamProvider.autoDispose<List<Goal>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final dao = ref.read(goalDaoProvider);
  return dao.watchGoals(userId);
});

final goalActionsProvider = Provider<GoalActions>((ref) {
  return GoalActions(ref.read(goalDaoProvider));
});

/// Local-first goal mutations (write Drift first, mark dirty).
class GoalActions {
  GoalActions(this._dao);
  final GoalDao _dao;
  final _uuid = const Uuid();


  Future<void> create({
    required String userId,
    required String title,
    String category = 'personal',
  }) async {
    final now = DateTime.now();
    await _dao.insertGoal(GoalsCompanion(
      id: Value(_uuid.v4()),
      userId: Value(userId),
      title: Value(title),
      category: Value(category),
      priority: const Value('medium'),
      status: const Value('notStarted'),
      progress: const Value(0.0),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
  }


  Future<void> delete(String id) => _dao.softDeleteGoal(id, DateTime.now());


}
