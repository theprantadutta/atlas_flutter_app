import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/tasks_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AtlasDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Future<List<Task>> getAllTasks(String userId) {
    return (select(tasks)..where((t) => t.userId.equals(userId))).get();
  }

  Future<Task?> getTaskById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertTask(TasksCompanion entry) {
    return into(tasks).insert(entry);
  }

  Future<int> upsertTask(TasksCompanion entry) {
    return into(tasks).insertOnConflictUpdate(entry);
  }

  Future<bool> updateTask(TasksCompanion entry) {
    return update(tasks).replace(entry);
  }

  Future<int> deleteTask(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Task>> getPendingTasks(String userId) {
    return (select(tasks)
          ..where(
              (t) => t.userId.equals(userId) & t.isCompleted.equals(false)))
        .get();
  }

  Future<List<Task>> getCompletedTasks(String userId) {
    return (select(tasks)
          ..where(
              (t) => t.userId.equals(userId) & t.isCompleted.equals(true)))
        .get();
  }
}
