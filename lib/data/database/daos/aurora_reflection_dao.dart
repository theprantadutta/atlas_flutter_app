import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/aurora_reflections_table.dart';

part 'aurora_reflection_dao.g.dart';

@DriftAccessor(tables: [AuroraReflections])
class AuroraReflectionDao extends DatabaseAccessor<AtlasDatabase>
    with _$AuroraReflectionDaoMixin {
  AuroraReflectionDao(super.db);

  /// Reactive stream of the user's most recent reflection (or null).
  Stream<AuroraReflection?> watchLatest(String userId) {
    return (select(auroraReflections)
          ..where((r) => r.userId.equals(userId))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> upsert(AuroraReflectionsCompanion entry) =>
      into(auroraReflections).insertOnConflictUpdate(entry);
}
