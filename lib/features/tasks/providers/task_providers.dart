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


  Future<void> create({
    required String userId,
    required String title,
    String? note,
    String category = 'custom',
    String type = 'daily',
    int xp = 25,
    String? dueTime,
  }) async {
    final now = DateTime.now();
    // An "HH:mm" time puts it on today's list at that time.
    final hm = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(dueTime ?? '');
    final due = hm == null
        ? null
        : DateTime(now.year, now.month, now.day, int.parse(hm[1]!), int.parse(hm[2]!));
    await _dao.insertTask(TasksCompanion(
      id: Value(_uuid.v4()),
      userId: Value(userId),
      title: Value(title),
      description: Value(note),
      type: Value(type),
      category: Value(category),
      xpReward: Value(xp),
      dueDate: Value(due),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
  }



  Future<void> delete(String id) => _dao.softDeleteTask(id, DateTime.now());


}
