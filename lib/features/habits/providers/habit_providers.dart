import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/habit_dao.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;

/// Reactive stream of the current user's habits from Drift (source of truth).
final habitsStreamProvider = StreamProvider.autoDispose<List<Habit>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final dao = ref.read(habitDaoProvider);
  ref.read(habitActionsProvider).ensureSeeded(userId);
  return dao.watchHabits(userId);
});

final habitActionsProvider = Provider<HabitActions>((ref) {
  return HabitActions(ref.read(habitDaoProvider));
});

/// Local-first habit mutations (write Drift first, mark dirty).
class HabitActions {
  HabitActions(this._dao);
  final HabitDao _dao;
  final _uuid = const Uuid();
  final _seeded = <String>{};

  Future<void> create({
    required String userId,
    required String title,
    String? note,
    String category = 'custom',
    String frequency = 'daily',
  }) async {
    final now = DateTime.now();
    await _dao.insertHabit(HabitsCompanion(
      id: Value(_uuid.v4()),
      userId: Value(userId),
      title: Value(title),
      description: Value(note),
      category: Value(category),
      frequency: Value(frequency),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
  }

  Future<void> toggleComplete(Habit row) async {
    final now = DateTime.now();
    final next = !row.isCompletedToday;
    final streak =
        next ? row.streakCount + 1 : (row.streakCount - 1).clamp(0, 1 << 30);
    final longest = streak > row.longestStreak ? streak : row.longestStreak;
    await _dao.updateFields(
      row.id,
      HabitsCompanion(
        isCompletedToday: Value(next),
        streakCount: Value(streak),
        longestStreak: Value(longest),
        totalCompletions:
            Value(next ? row.totalCompletions + 1 : row.totalCompletions),
        lastCompletedDate: Value(next ? now : null),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> delete(String id) => _dao.softDeleteHabit(id, DateTime.now());

  Future<void> ensureSeeded(String userId) async {
    if (_seeded.contains(userId)) return;
    _seeded.add(userId);
    if (await _dao.countForUser(userId) > 0) return;
    final now = DateTime.now();
    // title, note, category, frequency, streak, doneToday
    const seeds = [
      ['Meditate', '10 min of calm', 'mindfulness', 'daily', 12, true],
      ['Drink water', '8 glasses', 'health', 'daily', 5, true],
      ['Move your body', 'Any movement counts', 'fitness', 'daily', 3, false],
      ['Call a friend', 'Stay connected', 'social', 'weekly', 2, false],
    ];
    for (final s in seeds) {
      await _dao.insertHabit(HabitsCompanion(
        id: Value(_uuid.v4()),
        userId: Value(userId),
        title: Value(s[0] as String),
        description: Value(s[1] as String),
        category: Value(s[2] as String),
        frequency: Value(s[3] as String),
        streakCount: Value(s[4] as int),
        longestStreak: Value(s[4] as int),
        isCompletedToday: Value(s[5] as bool),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ));
    }
  }
}
