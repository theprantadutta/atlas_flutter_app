import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart' as db;
import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/models/task.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

/// Local-first Task repository: the Drift database is the source of truth.
/// Every write lands in Drift first and is marked dirty for later (premium)
/// sync — the network is never in the read/write path.
class TaskRepository extends BaseRepository {
  final TaskDao _taskDao;
  final _uuid = const Uuid();

  TaskRepository(
    super.apiService,
    super.offlineManager,
    this._taskDao,
  );

  // ─── READ ─────────────────────────────────────────────────────

  Future<List<Task>> getTasks({
    String? category,
    String? type,
    String? status,
    String? search,
  }) async {
    final rows = await _taskDao.getAllTasks(currentUserId);
    Iterable<Task> tasks = rows.map(_toModel);
    if (category != null) tasks = tasks.where((t) => t.category.name == category);
    if (type != null) tasks = tasks.where((t) => t.type.name == type);
    if (status == 'completed') tasks = tasks.where((t) => t.isCompleted);
    if (status == 'pending') tasks = tasks.where((t) => !t.isCompleted);
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      tasks = tasks.where((t) => t.title.toLowerCase().contains(q));
    }
    return tasks.toList();
  }

  Future<Task> getTaskById(String id) async {
    final row = await _taskDao.getTaskById(id);
    if (row == null) throw Exception('Task $id not found');
    return _toModel(row);
  }

  // ─── WRITE (local-first) ──────────────────────────────────────

  Future<Task> createTask(Map<String, dynamic> data) async {
    final now = DateTime.now();
    final id = data['id']?.toString() ?? _uuid.v4();
    final companion = db.TasksCompanion(
      id: Value(id),
      userId: Value(data['user_id']?.toString() ?? currentUserId),
      title: Value(data['title']?.toString() ?? ''),
      description: Value(data['description']?.toString()),
      type: Value(data['type']?.toString() ?? 'daily'),
      category: Value(data['category']?.toString() ?? 'custom'),
      xpReward: Value((data['xp_reward'] as int?) ?? 25),
      difficulty: Value((data['difficulty'] as int?) ?? 1),
      isCompleted: Value((data['is_completed'] as bool?) ?? false),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(true),
    );
    await _taskDao.insertTask(companion);
    return getTaskById(id);
  }

  Future<Task> updateTask(String id, Map<String, dynamic> data) async {
    final now = DateTime.now();
    await _taskDao.updateFields(
      id,
      db.TasksCompanion(
        title: data.containsKey('title')
            ? Value(data['title'].toString())
            : const Value.absent(),
        description: data.containsKey('description')
            ? Value(data['description']?.toString())
            : const Value.absent(),
        category: data.containsKey('category')
            ? Value(data['category'].toString())
            : const Value.absent(),
        type: data.containsKey('type')
            ? Value(data['type'].toString())
            : const Value.absent(),
        isCompleted: data.containsKey('is_completed')
            ? Value(data['is_completed'] as bool)
            : const Value.absent(),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
    return getTaskById(id);
  }

  Future<Map<String, dynamic>> completeTask(String id) async {
    final row = await _taskDao.getTaskById(id);
    final now = DateTime.now();
    final nextCompleted = !(row?.isCompleted ?? false);
    await _taskDao.updateFields(
      id,
      db.TasksCompanion(
        isCompleted: Value(nextCompleted),
        lastCompletedDate: Value(nextCompleted ? now : null),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
    return {'id': id, 'is_completed': nextCompleted};
  }

  Future<void> deleteTask(String id) async {
    await _taskDao.softDeleteTask(id, DateTime.now());
  }

  Future<Map<String, dynamic>> batchComplete(List<String> taskIds) async {
    for (final id in taskIds) {
      await completeTask(id);
    }
    return {'completed': taskIds.length, 'task_ids': taskIds};
  }

  // Stats are derived from local data for now.
  Future<Map<String, dynamic>> getTaskStats() async => {};
  Future<Map<String, dynamic>> getTaskTrend() async => {};

  // ─── Mapping ──────────────────────────────────────────────────

  Task _toModel(db.Task row) => Task.fromJson(_rowToJson(row));

  Map<String, dynamic> _rowToJson(db.Task row) => {
        'id': row.id,
        'user_id': row.userId,
        'title': row.title,
        'description': row.description,
        'type': row.type,
        'category': row.category,
        'xp_reward': row.xpReward,
        'difficulty': row.difficulty,
        'due_date': row.dueDate?.toIso8601String(),
        'is_completed': row.isCompleted,
        'streak_count': row.streakCount,
        'last_completed_date': row.lastCompletedDate?.toIso8601String(),
        'created_at': row.createdAt.toIso8601String(),
        'updated_at': row.updatedAt.toIso8601String(),
      };
}
