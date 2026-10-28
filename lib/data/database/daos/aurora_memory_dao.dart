import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/aurora_memories_table.dart';

part 'aurora_memory_dao.g.dart';

/// Local-only Aurora memories (deliberately never synced).
@DriftAccessor(tables: [AuroraMemories])
class AuroraMemoryDao extends DatabaseAccessor<AtlasDatabase>
    with _$AuroraMemoryDaoMixin {
  AuroraMemoryDao(super.db);

  static const _rowid = CustomExpression<int>('rowid');

  SimpleSelectStatement<$AuroraMemoriesTable, AuroraMemory> _all(
      String userId,
      {int? limit}) {
    final q = select(auroraMemories)
      ..where((m) => m.userId.equals(userId))
      ..orderBy([
        (m) => OrderingTerm.desc(m.createdAt),
        (_) => OrderingTerm.desc(_rowid),
      ]);
    if (limit != null) q.limit(limit);
    return q;
  }

  /// Newest first.
  Stream<List<AuroraMemory>> watchAll(String userId) => _all(userId).watch();

  Future<List<AuroraMemory>> getAll(String userId, {int? limit}) =>
      _all(userId, limit: limit).get();

  Future<void> insert(AuroraMemoriesCompanion entry) =>
      into(auroraMemories).insertOnConflictUpdate(entry);

  Future<int> deleteById(String id) =>
      (delete(auroraMemories)..where((m) => m.id.equals(id))).go();

  Future<int> deleteAllFor(String userId) =>
      (delete(auroraMemories)..where((m) => m.userId.equals(userId))).go();
}
