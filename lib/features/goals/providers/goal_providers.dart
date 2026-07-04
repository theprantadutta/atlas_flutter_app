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

  /// Deterministic ids for opt-in starter content (removable later).
  static const seedIds = [
    'seed-goal-0',
    'seed-goal-1',
    'seed-goal-2',
    'seed-goal-3',
  ];

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

  /// Nudge a goal forward — a satisfying local-first write.
  Future<void> bumpProgress(Goal row) async {
    final now = DateTime.now();
    final next = (row.progress + 0.25).clamp(0.0, 1.0);
    final done = next >= 1.0;
    await _dao.updateFields(
      row.id,
      GoalsCompanion(
        progress: Value(next),
        status: Value(done ? 'completed' : 'inProgress'),
        completedAt: done ? Value(now) : const Value(null),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> delete(String id) => _dao.softDeleteGoal(id, DateTime.now());

  /// Opt-in starter content (only seeded when the user asks for example data).
  Future<void> seedStarter(String userId) async {
    if (await _dao.countForUser(userId) > 0) return;
    final now = DateTime.now();
    // title, category, progress, status, deadlineInDays (null = none)
    final seeds = <List<dynamic>>[
      ['Run a half marathon', 'fitness', 0.62, 'inProgress', 42],
      ['Read 24 books this year', 'learning', 0.46, 'inProgress', 180],
      ['Save for a trip', 'financial', 0.8, 'inProgress', 18],
      ['Learn watercolor basics', 'creative', 1.0, 'completed', null],
    ];
    for (var i = 0; i < seeds.length; i++) {
      final s = seeds[i];
      final days = s[4] as int?;
      await _dao.insertGoal(GoalsCompanion(
        id: Value(seedIds[i]),
        userId: Value(userId),
        title: Value(s[0] as String),
        category: Value(s[1] as String),
        priority: const Value('medium'),
        status: Value(s[3] as String),
        progress: Value(s[2] as double),
        deadline: Value(days == null ? null : now.add(Duration(days: days))),
        completedAt: Value((s[3] as String) == 'completed' ? now : null),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ));
    }
  }

  /// Remove the opt-in starter content (soft-delete so it can sync).
  Future<void> deleteStarter(String userId) async {
    final now = DateTime.now();
    for (final id in seedIds) {
      await _dao.softDeleteGoal(id, now);
    }
  }
}
