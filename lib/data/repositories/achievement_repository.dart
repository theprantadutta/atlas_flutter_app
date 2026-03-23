import 'package:atlas_flutter_app/core/utils/lru_cache.dart';
import 'package:atlas_flutter_app/data/database/daos/achievement_dao.dart';
import 'package:atlas_flutter_app/data/models/achievement.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class AchievementRepository extends BaseRepository {
  final AchievementDao _achievementDao;

  AchievementRepository(
    super.apiService,
    super.offlineManager,
    this._achievementDao,
  );

  // ─── Caches ──────────────────────────────────────────────────

  final LRUCache<String, List<Achievement>> _collectionCache =
      LRUCache(maxSize: 100, ttl: Duration(minutes: 10));
  final LRUCache<String, Achievement> _entityCache =
      LRUCache(maxSize: 200, ttl: Duration(minutes: 10));
  final LRUCache<String, Map<String, dynamic>> _statsCache =
      LRUCache(maxSize: 50, ttl: Duration(minutes: 10));

  // ─── Cache key helpers ───────────────────────────────────────

  String _collectionKey({
    String? type,
    bool? unlocked,
    String? search,
  }) =>
      'achievements:$type:$unlocked:$search';

  // ─── READ operations ─────────────────────────────────────────

  /// Get achievements with optional filters.
  Future<List<Achievement>> getAchievements({
    String? type,
    bool? unlocked,
    String? search,
  }) async {
    final cacheKey = _collectionKey(
      type: type,
      unlocked: unlocked,
      search: search,
    );

    // 1. Check LRU cache
    final cached = _collectionCache.get(cacheKey);
    if (cached != null) return cached;

    // 2. If online, try API
    if (isOnline) {
      try {
        final queryParams = <String, dynamic>{};
        if (type != null) queryParams['type'] = type;
        if (unlocked != null) queryParams['unlocked'] = unlocked.toString();
        if (search != null) queryParams['search'] = search;

        final response = await apiService.get(
          '/achievements',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );
        final achievements =
            parseList(response.data, Achievement.fromJson);

        _collectionCache.put(cacheKey, achievements);
        for (final achievement in achievements) {
          _entityCache.put(achievement.id, achievement);
        }
        return achievements;
      } catch (_) {
        // API failed — fall through to DAO
      }
    }

    // 3. Offline fallback: read from local DAO
    try {
      final localAchievements =
          await _achievementDao.getAllAchievements('');
      final achievements = localAchievements
          .map((a) => Achievement.fromJson(_driftAchievementToJson(a)))
          .toList();
      _collectionCache.put(cacheKey, achievements);
      return achievements;
    } catch (_) {
      return [];
    }
  }

  /// Get recently unlocked achievements.
  Future<List<Achievement>> getRecentUnlocks() async {
    const cacheKey = 'achievements:recent';

    final cached = _collectionCache.get(cacheKey);
    if (cached != null) return cached;

    if (isOnline) {
      try {
        final response = await apiService.get('/achievements/recent');
        final achievements =
            parseList(response.data, Achievement.fromJson);
        _collectionCache.put(cacheKey, achievements);
        for (final achievement in achievements) {
          _entityCache.put(achievement.id, achievement);
        }
        return achievements;
      } catch (_) {
        // Fall through
      }
    }

    // Offline fallback: filter unlocked from local DAO
    try {
      final localUnlocked =
          await _achievementDao.getUnlockedAchievements('');
      final achievements = localUnlocked
          .map((a) => Achievement.fromJson(_driftAchievementToJson(a)))
          .toList();
      _collectionCache.put(cacheKey, achievements);
      return achievements;
    } catch (_) {
      return [];
    }
  }

  /// Check for new achievement unlocks.
  Future<Map<String, dynamic>> checkAchievements() async {
    if (isOnline) {
      try {
        final response = await apiService.post('/achievements/check');
        // Invalidate caches since new achievements may have been unlocked
        _collectionCache.clear();
        _entityCache.clear();
        _statsCache.clear();
        return response.data as Map<String, dynamic>;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'check',
      entityType: 'achievement',
      entityId: 'all',
    );

    return {'checked': true, 'offline': true};
  }

  // ─── Helpers ─────────────────────────────────────────────────

  Map<String, dynamic> _driftAchievementToJson(dynamic driftAchievement) {
    return {
      'id': driftAchievement.id,
      'user_id': driftAchievement.userId,
      'title': driftAchievement.title,
      'description': driftAchievement.description,
      'icon_path': driftAchievement.iconPath,
      'achievement_type': driftAchievement.achievementType,
      'criteria': driftAchievement.criteria,
      'is_unlocked': driftAchievement.isUnlocked,
      'progress': driftAchievement.progress,
      'unlocked_at': driftAchievement.unlockedAt?.toIso8601String(),
      'created_at': driftAchievement.createdAt.toIso8601String(),
      'updated_at': driftAchievement.updatedAt.toIso8601String(),
    };
  }
}
