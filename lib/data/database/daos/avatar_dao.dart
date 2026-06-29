import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/avatars_table.dart';

part 'avatar_dao.g.dart';

@DriftAccessor(tables: [Avatars])
class AvatarDao extends DatabaseAccessor<AtlasDatabase>
    with _$AvatarDaoMixin {
  AvatarDao(super.db);

  // ─── Reads (Avatar is 1:1 per user; excludes tombstones) ───

  /// Reactive single avatar for the user — the source of truth for the UI.
  Stream<Avatar?> watchAvatar(String userId) {
    return (select(avatars)
          ..where((a) => a.userId.equals(userId) & a.isDeleted.equals(false)))
        .watchSingleOrNull();
  }

  Future<Avatar?> getAvatarByUserId(String userId) {
    return (select(avatars)..where((a) => a.userId.equals(userId)))
        .getSingleOrNull();
  }

  // ─── Writes ───

  Future<int> insertAvatar(AvatarsCompanion entry) =>
      into(avatars).insert(entry);

  Future<int> upsertAvatar(AvatarsCompanion entry) {
    return into(avatars).insertOnConflictUpdate(entry);
  }

  Future<void> updateFields(String id, AvatarsCompanion patch) async {
    await (update(avatars)..where((a) => a.id.equals(id))).write(patch);
  }

  Future<void> softDeleteAvatar(String id, DateTime now) async {
    await (update(avatars)..where((a) => a.id.equals(id))).write(
      AvatarsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  // ─── Sync helpers ───

  Future<List<Avatar>> getDirtyAvatars(String userId) {
    return (select(avatars)
          ..where((a) => a.userId.equals(userId) & a.isDirty.equals(true)))
        .get();
  }

  Future<void> markSynced(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    await (update(avatars)..where((a) => a.id.isIn(ids))).write(
      AvatarsCompanion(
        isDirty: const Value(false),
        lastSyncedAt: Value(syncedAt),
      ),
    );
  }

  Future<int> purgeSyncedTombstones() {
    return (delete(avatars)
          ..where((a) => a.isDeleted.equals(true) & a.isDirty.equals(false)))
        .go();
  }
}
