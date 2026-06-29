import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart' as db;
import 'package:atlas_flutter_app/data/database/daos/world_dao.dart';
import 'package:atlas_flutter_app/data/models/world_tile.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

/// Local-first World repository: Drift is the source of truth.
class WorldRepository extends BaseRepository {
  final WorldDao _worldDao;

  WorldRepository(
    super.apiService,
    super.offlineManager,
    this._worldDao,
  );

  // ─── READ ─────────────────────────────────────────────────────

  Future<List<WorldTile>> getWorldTiles() async {
    final rows = await _worldDao.getAllTiles(currentUserId);
    return rows.map(_toModel).toList();
  }

  Future<WorldTile?> getTileById(String id) async {
    final row = await _worldDao.getTileById(id);
    return row == null ? null : _toModel(row);
  }

  // ─── WRITE (local-first) ──────────────────────────────────────

  /// Light a dormant tile to life. Writes Drift first and marks it dirty.
  Future<void> unlockTile(String id) async {
    final now = DateTime.now();
    await _worldDao.updateFields(
      id,
      db.WorldTilesCompanion(
        isUnlocked: const Value(true),
        unlockedAt: Value(now),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }

  // ─── Mapping ──────────────────────────────────────────────────

  WorldTile _toModel(db.WorldTile row) => WorldTile.fromJson(_rowToJson(row));

  Map<String, dynamic> _rowToJson(db.WorldTile row) => {
        'id': row.id,
        'user_id': row.userId,
        'name': row.name,
        'description': row.description,
        'image_path': row.imagePath,
        'tile_type': row.tileType,
        'is_unlocked': row.isUnlocked,
        'unlock_requirement': row.unlockRequirement,
        'unlock_category': row.unlockCategory,
        'position_x': row.positionX,
        'position_y': row.positionY,
        'unlocked_at': row.unlockedAt?.toIso8601String(),
        'custom_properties': row.customProperties,
        'created_at': row.createdAt.toIso8601String(),
        'updated_at': row.updatedAt.toIso8601String(),
      };
}
