import 'dart:convert';

import 'package:atlas_flutter_app/data/database/atlas_database.dart' as db;
import 'package:atlas_flutter_app/data/database/daos/progress_dao.dart';
import 'package:atlas_flutter_app/data/models/progress_entry.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

/// Local-first Progress repository: Drift is the source of truth.
class ProgressRepository extends BaseRepository {
  final ProgressDao _progressDao;

  ProgressRepository(
    super.apiService,
    super.offlineManager,
    this._progressDao,
  );

  // ─── READ ─────────────────────────────────────────────────────

  Future<List<ProgressEntry>> getProgress({
    String? startDate,
    String? endDate,
  }) async {
    final start = startDate != null
        ? DateTime.parse(startDate)
        : DateTime.now().subtract(const Duration(days: 30));
    final end = endDate != null ? DateTime.parse(endDate) : DateTime.now();
    final rows =
        await _progressDao.getProgressByDateRange(currentUserId, start, end);
    return rows.map(_toModel).toList();
  }

  // ─── Mapping ──────────────────────────────────────────────────

  ProgressEntry _toModel(db.ProgressEntry row) =>
      ProgressEntry.fromJson(_rowToJson(row));

  Map<String, dynamic> _rowToJson(db.ProgressEntry row) {
    Map<String, dynamic>? decode(String? s) {
      if (s == null || s.isEmpty) return null;
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    return {
      'id': row.id,
      'user_id': row.userId,
      'date': row.date.toIso8601String(),
      'xp_gained': row.xpGained,
      'tasks_completed': row.tasksCompleted,
      'category': row.category,
      'category_breakdown': decode(row.categoryBreakdown),
      'task_type_breakdown': decode(row.taskTypeBreakdown),
      'streak_count': row.streakCount,
      'level_at_time': row.levelAtTime,
      'additional_metrics': decode(row.additionalMetrics),
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }
}
