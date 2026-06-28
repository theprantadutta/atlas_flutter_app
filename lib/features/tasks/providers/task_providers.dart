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
  // Seed a few starter tasks once so a fresh offline DB isn't empty.
  ref.read(taskActionsProvider).ensureSeeded(userId);
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
  final _seeded = <String>{};

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

  Future<void> delete(String id) => _dao.softDeleteTask(id, DateTime.now());

  /// One-time starter content so the local DB demonstrates persistence.
  Future<void> ensureSeeded(String userId) async {
    if (_seeded.contains(userId)) return;
    _seeded.add(userId);
    if (await _dao.countForUser(userId) > 0) return;
    final now = DateTime.now();
    const seeds = [
      ['Reply to Sam', 'Due today', 'work', 'daily', 25],
      ['Stretch for 10 min', 'Loosen up', 'fitness', 'daily', 30],
      ['Plan the week', 'Sunday ritual', 'mindfulness', 'weekly', 45],
      ['Read "Atomic Habits"', '38% through', 'learning', 'longTerm', 90],
    ];
    for (final s in seeds) {
      await _dao.insertTask(TasksCompanion(
        id: Value(_uuid.v4()),
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
}
