import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/sync_operations_table.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncOperations])
class SyncDao extends DatabaseAccessor<AtlasDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  Future<List<SyncOperation>> getPendingOperations() {
    return (select(syncOperations)
          ..orderBy([(s) => OrderingTerm.asc(s.timestamp)]))
        .get();
  }

  Future<int> insertOperation(SyncOperationsCompanion entry) {
    return into(syncOperations).insert(entry);
  }

  Future<int> deleteOperation(String id) {
    return (delete(syncOperations)..where((s) => s.id.equals(id))).go();
  }

  Future<int> clearAll() {
    return delete(syncOperations).go();
  }
}
