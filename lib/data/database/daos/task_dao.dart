import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/tasks_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AtlasDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  // ─── Reads (exclude soft-deleted tombstones) ───

  /// Reactive stream of a user's active (non-deleted) tasks, newest first.
  Stream<List<Task>> watchTasks(String userId) {
    return (select(tasks)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Future<List<Task>> getAllTasks(String userId) {
    return (select(tasks)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .get();
  }

  Future<Task?> getTaskById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> countForUser(String userId) async {
    final rows = await (select(tasks)
          ..where((t) => t.userId.equals(userId)))
        .get();
    return rows.length;
  }

  // ─── Writes ───

  Future<int> insertTask(TasksCompanion entry) => into(tasks).insert(entry);

  Future<int> upsertTask(TasksCompanion entry) =>
      into(tasks).insertOnConflictUpdate(entry);

  Future<void> updateFields(String id, TasksCompanion patch) async {
    await (update(tasks)..where((t) => t.id.equals(id))).write(patch);
  }

  /// Soft-delete: keep a dirty tombstone so the deletion can sync.
  Future<void> softDeleteTask(String id, DateTime now) async {
    await (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  /// Hard-delete (used by sync cleanup once a tombstone is confirmed synced).
  Future<int> hardDeleteTask(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Backwards-compatible hard delete alias.
  Future<int> deleteTask(String id) => hardDeleteTask(id);

  Future<List<Task>> getPendingTasks(String userId) {
    return (select(tasks)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isCompleted.equals(false) &
              t.isDeleted.equals(false)))
        .get();
  }

  // ─── Sync helpers ───

  /// Rows that still need to be pushed to the server (incl. tombstones).
  Future<List<Task>> getDirtyTasks(String userId) {
    return (select(tasks)
          ..where((t) => t.userId.equals(userId) & t.isDirty.equals(true)))
        .get();
  }

  /// Mark rows as cleanly synced.
  Future<void> markSynced(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    await (update(tasks)..where((t) => t.id.isIn(ids))).write(
      TasksCompanion(isDirty: const Value(false), lastSyncedAt: Value(syncedAt)),
    );
  }

  /// Purge tombstones that have been confirmed synced.
  Future<int> purgeSyncedTombstones() {
    return (delete(tasks)
          ..where((t) => t.isDeleted.equals(true) & t.isDirty.equals(false)))
        .go();
  }
}
