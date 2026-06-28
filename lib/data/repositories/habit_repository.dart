import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart' as db;
import 'package:atlas_flutter_app/data/database/daos/habit_dao.dart';
import 'package:atlas_flutter_app/data/models/habit.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

/// Local-first Habit repository: Drift is the source of truth. Writes land
/// locally first and are marked dirty for later (premium) sync.
class HabitRepository extends BaseRepository {
  final HabitDao _habitDao;
  final _uuid = const Uuid();

  HabitRepository(
    super.apiService,
    super.offlineManager,
    this._habitDao,
  );

  // ─── READ ─────────────────────────────────────────────────────

  Future<List<Habit>> getHabits({
    String? category,
    String? frequency,
    String? search,
  }) async {
    final rows = await _habitDao.getAllHabits(currentUserId);
    Iterable<Habit> habits = rows.map(_toModel);
    if (category != null) {
      habits = habits.where((h) => h.category.name == category);
    }
    if (frequency != null) {
      habits = habits.where((h) => h.frequency.name == frequency);
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      habits = habits.where((h) => h.title.toLowerCase().contains(q));
    }
    return habits.toList();
  }

  Future<Habit> getHabitById(String id) async {
    final row = await _habitDao.getHabitById(id);
    if (row == null) throw Exception('Habit $id not found');
    return _toModel(row);
  }

  // ─── WRITE (local-first) ──────────────────────────────────────

  Future<Habit> createHabit(Map<String, dynamic> data) async {
    final now = DateTime.now();
    final id = data['id']?.toString() ?? _uuid.v4();
    await _habitDao.insertHabit(db.HabitsCompanion(
      id: Value(id),
      userId: Value(data['user_id']?.toString() ?? currentUserId),
      title: Value(data['title']?.toString() ?? ''),
      description: Value(data['description']?.toString()),
      category: Value(data['category']?.toString() ?? 'custom'),
      frequency: Value(data['frequency']?.toString() ?? 'daily'),
      difficulty: Value((data['difficulty'] as int?) ?? 1),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
    return getHabitById(id);
  }

  Future<Habit> updateHabit(String id, Map<String, dynamic> data) async {
    final now = DateTime.now();
    await _habitDao.updateFields(
      id,
      db.HabitsCompanion(
        title: data.containsKey('title')
            ? Value(data['title'].toString())
            : const Value.absent(),
        description: data.containsKey('description')
            ? Value(data['description']?.toString())
            : const Value.absent(),
        category: data.containsKey('category')
            ? Value(data['category'].toString())
            : const Value.absent(),
        frequency: data.containsKey('frequency')
            ? Value(data['frequency'].toString())
            : const Value.absent(),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
    return getHabitById(id);
  }

  Future<Map<String, dynamic>> completeHabit(String id) async {
    final row = await _habitDao.getHabitById(id);
    final now = DateTime.now();
    final next = !(row?.isCompletedToday ?? false);
    final streak = next
        ? (row?.streakCount ?? 0) + 1
        : ((row?.streakCount ?? 1) - 1).clamp(0, 1 << 30);
    await _habitDao.updateFields(
      id,
      db.HabitsCompanion(
        isCompletedToday: Value(next),
        streakCount: Value(streak),
        lastCompletedDate: Value(next ? now : null),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
    return {'id': id, 'is_completed_today': next};
  }

  Future<void> deleteHabit(String id) async {
    await _habitDao.softDeleteHabit(id, DateTime.now());
  }

  // ─── Mapping ──────────────────────────────────────────────────

  Habit _toModel(db.Habit row) => Habit.fromJson(_rowToJson(row));

  Map<String, dynamic> _rowToJson(db.Habit row) => {
        'id': row.id,
        'user_id': row.userId,
        'title': row.title,
        'description': row.description,
        'category': row.category,
        'frequency': row.frequency,
        'difficulty': row.difficulty,
        'is_completed_today': row.isCompletedToday,
        'streak_count': row.streakCount,
        'longest_streak': row.longestStreak,
        'completion_rate': row.completionRate,
        'total_completions': row.totalCompletions,
        'reminder_time': row.reminderTime,
        'last_completed_date': row.lastCompletedDate?.toIso8601String(),
        'created_at': row.createdAt.toIso8601String(),
        'updated_at': row.updatedAt.toIso8601String(),
      };
}
