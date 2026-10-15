import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';

/// Writes the local XP ledger (see [Ledger]). Local-first: every write lands
/// in Drift and is marked dirty; sync carries it later if enabled.
class XpLedgerService {
  XpLedgerService(this._db);

  final AtlasDatabase _db;

  /// The ledger row for [day], preferring the deterministic id but adopting
  /// any existing row for that day (legacy, server-made or seeded) so a day
  /// never ends up with two rows.
  Future<ProgressEntry?> _rowFor(String userId, DateTime day) async {
    final id = Ledger.entryId(userId, day);
    final byId = await (_db.select(_db.progressEntries)
          ..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    if (byId != null) return byId;
    final start = dateOnly(day);
    final end = addDays(start, 1);
    final rows = await (_db.select(_db.progressEntries)
          ..where((p) =>
              p.userId.equals(userId) &
              p.isDeleted.equals(false) &
              p.date.isBiggerOrEqualValue(start) &
              p.date.isSmallerThanValue(end))
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Record that [itemKey] earned [xp] on [day]. Idempotent: recording the
  /// same item twice on one day does nothing the second time.
  Future<void> record({
    required String userId,
    required String itemKey,
    required int xp,
    required String category,
    required String type,
    DateTime? day,
    int? streakCount,
    int? level,
  }) async {
    final d = dateOnly(day ?? DateTime.now());
    final now = DateTime.now();
    await _db.transaction(() async {
      final row = await _rowFor(userId, d);
      if (row == null) {
        await _db.into(_db.progressEntries).insert(ProgressEntriesCompanion.insert(
              id: Ledger.entryId(userId, d),
              userId: userId,
              date: d,
              xpGained: Value(xp),
              tasksCompleted: const Value(1),
              category: Value(category),
              categoryBreakdown: Value(LedgerDay.encode({category: xp})),
              taskTypeBreakdown: Value(LedgerDay.encode({type: 1})),
              additionalMetrics: Value(LedgerDay.encode({itemKey: xp})),
              streakCount: Value(streakCount ?? 0),
              levelAtTime: Value(level ?? 1),
              createdAt: now,
              updatedAt: now,
              isDirty: const Value(true),
            ));
        return;
      }
      final items = LedgerDay.decodeIntMap(row.additionalMetrics);
      if (items.containsKey(itemKey)) return;
      items[itemKey] = xp;
      final cats = LedgerDay.decodeIntMap(row.categoryBreakdown)
        ..update(category, (v) => v + xp, ifAbsent: () => xp);
      final types = LedgerDay.decodeIntMap(row.taskTypeBreakdown)
        ..update(type, (v) => v + 1, ifAbsent: () => 1);
      await (_db.update(_db.progressEntries)..where((p) => p.id.equals(row.id)))
          .write(ProgressEntriesCompanion(
        xpGained: Value(row.xpGained + xp),
        tasksCompleted: Value(row.tasksCompleted + 1),
        categoryBreakdown: Value(LedgerDay.encode(cats)),
        taskTypeBreakdown: Value(LedgerDay.encode(types)),
        additionalMetrics: Value(LedgerDay.encode(items)),
        streakCount: streakCount == null ? const Value.absent() : Value(streakCount),
        levelAtTime: level == null ? const Value.absent() : Value(level),
        isDeleted: const Value(false),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ));
    });
  }

  /// Reverse a recorded completion of [itemKey] on [day]. Returns the XP
  /// removed (0 if it wasn't recorded).
  Future<int> revoke({
    required String userId,
    required String itemKey,
    required String category,
    required String type,
    DateTime? day,
  }) async {
    final d = dateOnly(day ?? DateTime.now());
    var removed = 0;
    await _db.transaction(() async {
      final row = await _rowFor(userId, d);
      if (row == null) return;
      final items = LedgerDay.decodeIntMap(row.additionalMetrics);
      final xp = items.remove(itemKey);
      if (xp == null) return;
      removed = xp;
      final cats = LedgerDay.decodeIntMap(row.categoryBreakdown);
      if (cats.containsKey(category)) {
        cats[category] = cats[category]! - xp;
        if (cats[category]! <= 0) cats.remove(category);
      }
      final types = LedgerDay.decodeIntMap(row.taskTypeBreakdown);
      if (types.containsKey(type)) {
        types[type] = types[type]! - 1;
        if (types[type]! <= 0) types.remove(type);
      }
      await (_db.update(_db.progressEntries)..where((p) => p.id.equals(row.id)))
          .write(ProgressEntriesCompanion(
        xpGained: Value((row.xpGained - xp).clamp(0, 1 << 30)),
        tasksCompleted: Value((row.tasksCompleted - 1).clamp(0, 1 << 30)),
        categoryBreakdown: Value(LedgerDay.encode(cats)),
        taskTypeBreakdown: Value(LedgerDay.encode(types)),
        additionalMetrics: Value(LedgerDay.encode(items)),
        updatedAt: Value(DateTime.now()),
        isDirty: const Value(true),
      ));
    });
    return removed;
  }
}
