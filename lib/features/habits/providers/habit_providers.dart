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


  Future<void> create({
    required String userId,
    required String title,
    String? note,
    String category = 'custom',
    String frequency = 'daily',
    String? reminderTime,
  }) async {
    final now = DateTime.now();
    await _dao.insertHabit(HabitsCompanion(
      id: Value(_uuid.v4()),
      userId: Value(userId),
      title: Value(title),
      description: Value(note),
      category: Value(category),
      frequency: Value(frequency),
      reminderTime: Value(reminderTime),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
  }


  Future<void> delete(String id) => _dao.softDeleteHabit(id, DateTime.now());


}
