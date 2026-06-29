import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart' as db;
import 'package:atlas_flutter_app/data/database/daos/goal_dao.dart';
import 'package:atlas_flutter_app/data/models/goal.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

/// Local-first Goal repository: Drift is the source of truth.
class GoalRepository extends BaseRepository {
  final GoalDao _goalDao;
  final _uuid = const Uuid();

  GoalRepository(
    super.apiService,
    super.offlineManager,
    this._goalDao,
  );

  // ─── READ ─────────────────────────────────────────────────────

  Future<List<Goal>> getGoals({
    String? category,
    String? status,
    String? priority,
    String? search,
  }) async {
    final rows = await _goalDao.getAllGoals(currentUserId);
    Iterable<Goal> items = rows.map(_toModel);
    if (category != null) items = items.where((g) => g.category.name == category);
    if (status != null) items = items.where((g) => g.status.name == status);
    if (priority != null) items = items.where((g) => g.priority.name == priority);
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      items = items.where((g) => g.title.toLowerCase().contains(q));
    }
    return items.toList();
  }

  Future<Goal> getGoalById(String id) async {
    final row = await _goalDao.getGoalById(id);
    if (row == null) throw Exception('Goal $id not found');
    return _toModel(row);
  }

  // ─── WRITE (local-first) ──────────────────────────────────────

  Future<Goal> createGoal(Map<String, dynamic> data) async {
    final now = DateTime.now();
    final id = data['id']?.toString() ?? _uuid.v4();
    await _goalDao.insertGoal(db.GoalsCompanion(
      id: Value(id),
      userId: Value(data['user_id']?.toString() ?? currentUserId),
      title: Value(data['title']?.toString() ?? ''),
      description: Value(data['description']?.toString()),
      category: Value(data['category']?.toString() ?? 'personal'),
      priority: Value(data['priority']?.toString() ?? 'medium'),
      status: Value(data['status']?.toString() ?? 'notStarted'),
      progress: Value((data['progress'] as num?)?.toDouble() ?? 0.0),
      deadline: Value(_parse(data['deadline'])),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
    return getGoalById(id);
  }

  Future<Goal> updateGoal(String id, Map<String, dynamic> data) async {
    final now = DateTime.now();
    await _goalDao.updateFields(
      id,
      db.GoalsCompanion(
        title: data.containsKey('title')
            ? Value(data['title'].toString())
            : const Value.absent(),
        description: data.containsKey('description')
            ? Value(data['description']?.toString())
            : const Value.absent(),
        category: data.containsKey('category')
            ? Value(data['category'].toString())
            : const Value.absent(),
        priority: data.containsKey('priority')
            ? Value(data['priority'].toString())
            : const Value.absent(),
        status: data.containsKey('status')
            ? Value(data['status'].toString())
            : const Value.absent(),
        deadline: data.containsKey('deadline')
            ? Value(_parse(data['deadline']))
            : const Value.absent(),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
    return getGoalById(id);
  }

  Future<Goal> updateGoalProgress(String id, Map<String, dynamic> data) async {
    final now = DateTime.now();
    final progress = ((data['progress'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final done = progress >= 1.0;
    await _goalDao.updateFields(
      id,
      db.GoalsCompanion(
        progress: Value(progress),
        status: done ? const Value('completed') : const Value.absent(),
        completedAt: done ? Value(now) : const Value.absent(),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
    return getGoalById(id);
  }

  Future<void> deleteGoal(String id) async {
    await _goalDao.softDeleteGoal(id, DateTime.now());
  }

  // ─── Mapping ──────────────────────────────────────────────────

  static DateTime? _parse(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  Goal _toModel(db.Goal row) => Goal.fromJson(_rowToJson(row));

  Map<String, dynamic> _rowToJson(db.Goal row) => {
        'id': row.id,
        'user_id': row.userId,
        'title': row.title,
        'description': row.description,
        'category': row.category,
        'priority': row.priority,
        'status': row.status,
        'progress': row.progress,
        'start_date': row.startDate?.toIso8601String(),
        'deadline': row.deadline?.toIso8601String(),
        'completed_at': row.completedAt?.toIso8601String(),
        'parent_goal_id': row.parentGoalId,
        'created_at': row.createdAt.toIso8601String(),
        'updated_at': row.updatedAt.toIso8601String(),
      };
}
