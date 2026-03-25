import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/core/utils/lru_cache.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart' show WorldTilesCompanion;
import 'package:atlas_flutter_app/data/database/daos/world_dao.dart';
import 'package:atlas_flutter_app/data/models/world_tile.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class WorldRepository extends BaseRepository {
  final WorldDao _worldDao;

  WorldRepository(
    super.apiService,
    super.offlineManager,
    this._worldDao,
  );

  // ─── Caches ──────────────────────────────────────────────────

  final LRUCache<String, List<WorldTile>> _collectionCache =
      LRUCache(maxSize: 50, ttl: Duration(minutes: 10));
  final LRUCache<String, WorldTile> _entityCache =
      LRUCache(maxSize: 100, ttl: Duration(minutes: 10));
  final LRUCache<String, Map<String, dynamic>> _statsCache =
      LRUCache(maxSize: 20, ttl: Duration(minutes: 10));

  // ─── READ operations ─────────────────────────────────────────

  /// Get all world tiles.
  Future<List<WorldTile>> getWorldTiles() async {
    const cacheKey = 'world_tiles:all';

    // 1. Check LRU cache
    final cached = _collectionCache.get(cacheKey);
    if (cached != null) return cached;

    // 2. If online, try API
    if (isOnline) {
      try {
        final response = await apiService.get('/world/tiles');
        final tiles = parseList(response.data, WorldTile.fromJson);

        // Persist to local DB
        await _persistTilesToDb(tiles);

        _collectionCache.put(cacheKey, tiles);
        for (final tile in tiles) {
          _entityCache.put(tile.id, tile);
        }
        return tiles;
      } catch (_) {
        // API failed — fall through to DAO
      }
    }

    // 3. Offline fallback: read from local DAO
    try {
      final localTiles = await _worldDao.getAllTiles(currentUserId);
      final tiles = localTiles
          .map((t) => WorldTile.fromJson(_driftTileToJson(t)))
          .toList();
      _collectionCache.put(cacheKey, tiles);
      return tiles;
    } catch (_) {
      return [];
    }
  }

  // ─── WRITE operations ────────────────────────────────────────

  /// Seed the world map for the current user.
  Future<void> seedWorld() async {
    if (isOnline) {
      await apiService.post('/world/seed');
      _collectionCache.clear();
      _statsCache.clear();
    }
  }

  /// Unlock a specific world tile.
  Future<Map<String, dynamic>> unlockTile(String id) async {
    if (isOnline) {
      try {
        final response =
            await apiService.post('/world/tiles/$id/unlock');
        _entityCache.remove(id);
        _collectionCache.clear();
        _statsCache.clear();
        return response.data as Map<String, dynamic>;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'unlock',
      entityType: 'world_tile',
      entityId: id,
    );
    _entityCache.remove(id);
    _collectionCache.clear();
    _statsCache.clear();

    return {'id': id, 'is_unlocked': true};
  }

  // ─── STATS operations ───────────────────────────────────────

  /// Get world exploration statistics.
  Future<Map<String, dynamic>> getWorldStats() async {
    final cached = _statsCache.get('world_stats');
    if (cached != null) return cached;

    if (isOnline) {
      try {
        final response = await apiService.get('/world/stats');
        final stats = response.data as Map<String, dynamic>;
        _statsCache.put('world_stats', stats);
        return stats;
      } catch (_) {
        // Fall through
      }
    }

    return {};
  }

  // ─── DB Persistence Helpers ────────────────────────────────

  Future<void> _persistTilesToDb(List<WorldTile> tiles) async {
    for (final tile in tiles) {
      await _persistTileToDb(tile);
    }
  }

  Future<void> _persistTileToDb(WorldTile tile) async {
    try {
      await _worldDao.upsertTile(_toCompanion(tile));
    } catch (_) {
      // Ignore DB write errors
    }
  }

  WorldTilesCompanion _toCompanion(WorldTile tile) {
    return WorldTilesCompanion(
      id: Value(tile.id),
      userId: Value(tile.userId),
      name: Value(tile.name),
      description: Value(tile.description),
      imagePath: Value(tile.imagePath),
      tileType: Value(tile.tileType.name),
      isUnlocked: Value(tile.isUnlocked),
      unlockRequirement: Value(tile.unlockRequirement),
      unlockCategory: Value(tile.unlockCategory),
      positionX: Value(tile.positionX),
      positionY: Value(tile.positionY),
      unlockedAt: Value(tile.unlockedAt),
      customProperties: Value(
        tile.customProperties != null
            ? jsonEncode(tile.customProperties)
            : null,
      ),
      createdAt: Value(tile.createdAt),
      updatedAt: Value(tile.updatedAt),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  Map<String, dynamic> _driftTileToJson(dynamic driftTile) {
    return {
      'id': driftTile.id,
      'user_id': driftTile.userId,
      'name': driftTile.name,
      'description': driftTile.description,
      'image_path': driftTile.imagePath,
      'tile_type': driftTile.tileType,
      'is_unlocked': driftTile.isUnlocked,
      'unlock_requirement': driftTile.unlockRequirement,
      'unlock_category': driftTile.unlockCategory,
      'position_x': driftTile.positionX,
      'position_y': driftTile.positionY,
      'unlocked_at': driftTile.unlockedAt?.toIso8601String(),
      'custom_properties': driftTile.customProperties,
      'created_at': driftTile.createdAt.toIso8601String(),
      'updated_at': driftTile.updatedAt.toIso8601String(),
    };
  }
}
