import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/core/utils/lru_cache.dart';
import 'package:atlas_flutter_app/data/database/daos/avatar_dao.dart';
import 'package:atlas_flutter_app/data/models/avatar.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class AvatarRepository extends BaseRepository {
  final AvatarDao _avatarDao;

  AvatarRepository(
    super.apiService,
    super.offlineManager,
    this._avatarDao,
  );

  // ─── Caches ──────────────────────────────────────────────────

  final LRUCache<String, List<Avatar>> _collectionCache =
      LRUCache(maxSize: 100, ttl: Duration(minutes: 5));
  final LRUCache<String, Avatar> _entityCache =
      LRUCache(maxSize: 100, ttl: Duration(minutes: 5));
  final LRUCache<String, Map<String, dynamic>> _statsCache =
      LRUCache(maxSize: 50, ttl: Duration(minutes: 10));

  // ─── READ operations ─────────────────────────────────────────

  /// Get the current user's avatar.
  Future<Avatar> getAvatar() async {
    // 1. Check entity cache
    final cached = _entityCache.get('current_avatar');
    if (cached != null) return cached;

    // 2. If online, try API
    if (isOnline) {
      try {
        final response = await apiService.get('/avatar');
        final avatar = Avatar.fromJson(response.data as Map<String, dynamic>);
        _entityCache.put('current_avatar', avatar);
        _entityCache.put(avatar.id, avatar);
        return avatar;
      } catch (_) {
        // Fall through to DAO
      }
    }

    // 3. Offline fallback: read from local DAO
    try {
      final local = await _avatarDao.getAvatarByUserId('');
      if (local != null) {
        final avatar = Avatar.fromJson(_driftAvatarToJson(local));
        _entityCache.put('current_avatar', avatar);
        return avatar;
      }
    } catch (_) {
      // Fall through
    }

    throw Exception('Avatar not found');
  }

  // ─── WRITE operations ────────────────────────────────────────

  /// Create an avatar for the current user.
  Future<Avatar> createAvatar(Map<String, dynamic> data) async {
    if (isOnline) {
      try {
        final response = await apiService.post('/avatar', data: data);
        final avatar = Avatar.fromJson(response.data as Map<String, dynamic>);
        _entityCache.put('current_avatar', avatar);
        _entityCache.put(avatar.id, avatar);
        _collectionCache.clear();
        return avatar;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'create',
      entityType: 'avatar',
      entityId: data['id']?.toString() ?? const Uuid().v4(),
      data: data,
    );
    _collectionCache.clear();
    return Avatar.fromJson(data);
  }

  /// Update the avatar's appearance.
  Future<Avatar> updateAppearance(Map<String, dynamic> data) async {
    if (isOnline) {
      try {
        final response =
            await apiService.put('/avatar/appearance', data: data);
        final avatar = Avatar.fromJson(response.data as Map<String, dynamic>);
        _entityCache.put('current_avatar', avatar);
        _entityCache.put(avatar.id, avatar);
        return avatar;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'update_appearance',
      entityType: 'avatar',
      entityId: 'current',
      data: data,
    );
    _entityCache.remove('current_avatar');

    return Avatar.fromJson(data);
  }

  /// Unlock an item for the avatar.
  Future<Map<String, dynamic>> unlockItem(Map<String, dynamic> data) async {
    if (isOnline) {
      try {
        final response =
            await apiService.post('/avatar/unlock-item', data: data);
        _entityCache.remove('current_avatar');
        _statsCache.clear();
        return response.data as Map<String, dynamic>;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'unlock_item',
      entityType: 'avatar',
      entityId: 'current',
      data: data,
    );
    _entityCache.remove('current_avatar');
    _statsCache.clear();

    return {'unlocked': true, ...data};
  }

  /// Get avatar statistics.
  Future<Map<String, dynamic>> getAvatarStats() async {
    final cached = _statsCache.get('avatar_stats');
    if (cached != null) return cached;

    if (isOnline) {
      try {
        final response = await apiService.get('/avatar/stats');
        final stats = response.data as Map<String, dynamic>;
        _statsCache.put('avatar_stats', stats);
        return stats;
      } catch (_) {
        // Fall through
      }
    }

    return {};
  }

  // ─── Helpers ─────────────────────────────────────────────────

  Map<String, dynamic> _driftAvatarToJson(dynamic driftAvatar) {
    return {
      'id': driftAvatar.id,
      'user_id': driftAvatar.userId,
      'name': driftAvatar.name,
      'level': driftAvatar.level,
      'current_xp': driftAvatar.currentXp,
      'strength': driftAvatar.strength,
      'wisdom': driftAvatar.wisdom,
      'intelligence': driftAvatar.intelligence,
      'appearance': driftAvatar.appearanceData,
      'unlocked_items': driftAvatar.unlockedItems,
      'created_at': driftAvatar.createdAt.toIso8601String(),
      'updated_at': driftAvatar.updatedAt.toIso8601String(),
    };
  }
}
