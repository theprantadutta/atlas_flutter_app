import 'dart:convert';

import 'package:atlas_flutter_app/data/database/atlas_database.dart' as db;
import 'package:atlas_flutter_app/data/database/daos/achievement_dao.dart';
import 'package:atlas_flutter_app/data/models/achievement.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

/// Local-first Achievement repository: Drift is the source of truth.
class AchievementRepository extends BaseRepository {
  final AchievementDao _achievementDao;

  AchievementRepository(
    super.apiService,
    super.offlineManager,
    this._achievementDao,
  );

  // ─── READ ─────────────────────────────────────────────────────

  Future<List<Achievement>> getAchievements({
    String? type,
    bool? unlocked,
    String? search,
  }) async {
    final rows = await _achievementDao.getAllAchievements(currentUserId);
    Iterable<Achievement> items = rows.map(_toModel);
    if (type != null) items = items.where((a) => a.achievementType.name == type);
    if (unlocked != null) items = items.where((a) => a.isUnlocked == unlocked);
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      items = items.where((a) => a.title.toLowerCase().contains(q));
    }
    return items.toList();
  }

  Future<List<Achievement>> getRecentUnlocks() async {
    final rows = await _achievementDao.getUnlockedAchievements(currentUserId);
    return rows.map(_toModel).toList();
  }

  // ─── Mapping ──────────────────────────────────────────────────

  Achievement _toModel(db.Achievement row) =>
      Achievement.fromJson(_rowToJson(row));

  Map<String, dynamic> _rowToJson(db.Achievement row) {
    double targetValue = 0.0;
    String? category;
    if (row.criteria != null) {
      try {
        final m = jsonDecode(row.criteria!) as Map<String, dynamic>;
        targetValue = (m['target_value'] as num?)?.toDouble() ?? 0.0;
        category = m['category'] as String?;
      } catch (_) {
        // Ignore malformed criteria.
      }
    }
    return {
      'id': row.id,
      'user_id': row.userId,
      'title': row.title,
      'description': row.description,
      'icon_path': row.iconPath,
      'type': row.achievementType,
      'target_value': targetValue,
      'category': category,
      'is_unlocked': row.isUnlocked,
      'progress': row.progress,
      'unlocked_at': row.unlockedAt?.toIso8601String(),
      'badge_tier': 'bronze',
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }
}
