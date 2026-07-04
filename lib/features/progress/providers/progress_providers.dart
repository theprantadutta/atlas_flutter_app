import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/progress_dao.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;

/// Reactive stream of the current user's daily progress entries from Drift
/// (source of truth), most recent day first.
final progressEntriesStreamProvider =
    StreamProvider.autoDispose<List<ProgressEntry>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final dao = ref.read(progressDaoProvider);
  return dao.watchEntries(userId);
});

final progressActionsProvider = Provider<ProgressActions>((ref) {
  return ProgressActions(ref.read(progressDaoProvider));
});

/// Local-first progress mutations. Daily entries are normally rolled up from
/// completions; offline we seed a recent week so the ledger isn't empty.
class ProgressActions {
  ProgressActions(this._dao);
  final ProgressDao _dao;

  /// Deterministic ids for opt-in starter content (removable later).
  static const seedIds = [
    'seed-progress-0',
    'seed-progress-1',
    'seed-progress-2',
    'seed-progress-3',
    'seed-progress-4',
    'seed-progress-5',
    'seed-progress-6',
  ];

  /// Opt-in starter content (only seeded when the user asks for example data).
  Future<void> seedStarter(String userId) async {
    if (await _dao.countForUser(userId) > 0) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // dayOffset 0 = today; xp / tasks / streak per day.
    const xp = [175, 140, 200, 95, 160, 85, 120];
    const tasks = [4, 3, 5, 2, 4, 2, 3];
    const streak = [12, 11, 10, 9, 8, 7, 6];
    for (var i = 0; i < xp.length; i++) {
      final date = today.subtract(Duration(days: i));
      await _dao.insertProgress(ProgressEntriesCompanion(
        id: Value(seedIds[i]),
        userId: Value(userId),
        date: Value(date),
        xpGained: Value(xp[i]),
        tasksCompleted: Value(tasks[i]),
        streakCount: Value(streak[i]),
        levelAtTime: const Value(7),
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
      await _dao.softDeleteEntry(id, now);
    }
  }
}
