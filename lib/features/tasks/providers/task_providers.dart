import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';

/// The signed-in user's id (falls back to the local/demo user when offline).
final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(authProvider).user;
  return user?.id ?? 'demo-user';
});

/// Reactive stream of the current user's tasks straight from Drift — the
/// source of truth. The UI rebuilds whenever the local DB changes.
final tasksStreamProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final dao = ref.read(taskDaoProvider);
  return dao.watchTasks(userId);
});

final taskActionsProvider = Provider<TaskActions>((ref) {
  return TaskActions(ref.read(taskDaoProvider));
});

/// Local-first task mutations: every write lands in Drift first and is marked
/// dirty for later (premium) sync.
class TaskActions {
  TaskActions(this._dao);
  final TaskDao _dao;
  final _uuid = const Uuid();

  /// Deterministic ids for opt-in starter content, so it can be recognised
  /// and removed later (see the "Delete starter data" setting).
  static const seedIds = [
    'seed-task-0',
    'seed-task-1',
    'seed-task-2',
    'seed-task-3',
  ];

  Future<void> create({
    required String userId,
    required String title,
    String? note,
    String category = 'custom',
    String type = 'daily',
    int xp = 25,
  }) async {
    final now = DateTime.now();
    await _dao.insertTask(TasksCompanion(
      id: Value(_uuid.v4()),
      userId: Value(userId),
      title: Value(title),
      description: Value(note),
      type: Value(type),
      category: Value(category),
      xpReward: Value(xp),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
  }

  Future<void> toggleComplete(Task row) async {
    final now = DateTime.now();
    final next = !row.isCompleted;
    await _dao.updateFields(
      row.id,
      TasksCompanion(
        isCompleted: Value(next),
        lastCompletedDate: Value(next ? now : null),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }

  /// Toggle completion by id (used by the home screen's today list).
  Future<void> toggleById(String id) async {
    final row = await _dao.getTaskById(id);
    if (row != null) await toggleComplete(row);
  }

  Future<void> delete(String id) => _dao.softDeleteTask(id, DateTime.now());

  /// Opt-in starter content (only seeded when the user asks for example data).
  Future<void> seedStarter(String userId) async {
    if (await _dao.getTaskById(seedIds.first) != null) return;
    final now = DateTime.now();
    const seeds = [
      ['Reply to Sam', 'Due today', 'work', 'daily', 25],
      ['Stretch for 10 min', 'Loosen up', 'fitness', 'daily', 30],
      ['Plan the week', 'Sunday ritual', 'mindfulness', 'weekly', 45],
      ['Read "Atomic Habits"', '38% through', 'learning', 'longTerm', 90],
    ];
    for (var i = 0; i < seeds.length; i++) {
      final s = seeds[i];
      await _dao.insertTask(TasksCompanion(
        id: Value(seedIds[i]),
        userId: Value(userId),
        title: Value(s[0] as String),
        description: Value(s[1] as String),
        category: Value(s[2] as String),
        type: Value(s[3] as String),
        xpReward: Value(s[4] as int),
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
      await _dao.softDeleteTask(id, now);
    }
  }
}
