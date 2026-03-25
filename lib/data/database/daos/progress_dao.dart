import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/progress_entries_table.dart';

part 'progress_dao.g.dart';

@DriftAccessor(tables: [ProgressEntries])
class ProgressDao extends DatabaseAccessor<AtlasDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  Future<List<ProgressEntry>> getProgressByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return (select(progressEntries)
          ..where((p) =>
              p.userId.equals(userId) &
              p.date.isBiggerOrEqualValue(start) &
              p.date.isSmallerOrEqualValue(end)))
        .get();
  }

  Future<int> insertProgress(ProgressEntriesCompanion entry) {
    return into(progressEntries).insert(entry);
  }

  Future<int> upsertProgress(ProgressEntriesCompanion entry) {
    return into(progressEntries).insertOnConflictUpdate(entry);
  }

  Future<bool> updateProgress(ProgressEntriesCompanion entry) {
    return update(progressEntries).replace(entry);
  }

  Future<ProgressEntry?> getProgressForDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(progressEntries)
          ..where((p) =>
              p.userId.equals(userId) &
              p.date.isBiggerOrEqualValue(startOfDay) &
              p.date.isSmallerThanValue(endOfDay)))
        .getSingleOrNull();
  }
}
