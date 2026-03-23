import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/avatars_table.dart';

part 'avatar_dao.g.dart';

@DriftAccessor(tables: [Avatars])
class AvatarDao extends DatabaseAccessor<AtlasDatabase>
    with _$AvatarDaoMixin {
  AvatarDao(super.db);

  Future<Avatar?> getAvatarByUserId(String userId) {
    return (select(avatars)..where((a) => a.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<int> upsertAvatar(AvatarsCompanion entry) {
    return into(avatars).insertOnConflictUpdate(entry);
  }
}
