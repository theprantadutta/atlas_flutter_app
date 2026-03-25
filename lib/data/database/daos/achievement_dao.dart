import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/achievements_table.dart';

part 'achievement_dao.g.dart';

@DriftAccessor(tables: [Achievements])
class AchievementDao extends DatabaseAccessor<AtlasDatabase>
    with _$AchievementDaoMixin {
  AchievementDao(super.db);

  Future<List<Achievement>> getAllAchievements(String userId) {
    return (select(achievements)..where((a) => a.userId.equals(userId))).get();
  }

  Future<List<Achievement>> getUnlockedAchievements(String userId) {
    return (select(achievements)
          ..where(
              (a) => a.userId.equals(userId) & a.isUnlocked.equals(true)))
        .get();
  }

  Future<int> insertAchievement(AchievementsCompanion entry) {
    return into(achievements).insert(entry);
  }

  Future<int> upsertAchievement(AchievementsCompanion entry) {
    return into(achievements).insertOnConflictUpdate(entry);
  }

  Future<bool> updateAchievement(AchievementsCompanion entry) {
    return update(achievements).replace(entry);
  }
}
