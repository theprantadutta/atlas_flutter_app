import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/goals_table.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<AtlasDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  Future<List<Goal>> getAllGoals(String userId) {
    return (select(goals)..where((g) => g.userId.equals(userId))).get();
  }

  Future<Goal?> getGoalById(String id) {
    return (select(goals)..where((g) => g.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertGoal(GoalsCompanion entry) {
    return into(goals).insert(entry);
  }

  Future<bool> updateGoal(GoalsCompanion entry) {
    return update(goals).replace(entry);
  }

  Future<int> deleteGoal(String id) {
    return (delete(goals)..where((g) => g.id.equals(id))).go();
  }

  Future<List<Goal>> getActiveGoals(String userId) {
    return (select(goals)
          ..where((g) =>
              g.userId.equals(userId) &
              (g.status.equals('not_started') |
                  g.status.equals('in_progress'))))
        .get();
  }
}
