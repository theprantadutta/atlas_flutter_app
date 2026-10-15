import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/services/xp_ledger_service.dart';

/// Opt-in example content ("Show me around"), written straight to Drift.
///
/// - Ids are UUID v5 of the user and a slot, so they sync like any real row
///   (the server rejects anything that isn't a UUID) and are recognisable
///   later for removal.
/// - Everything is scoped by user id.
/// - Re-adding after removal revives the rows instead of silently skipping
///   tombstones.
/// - It comes with a believable history in the XP ledger (three weeks), so
///   Home, Grow's week strip, Insights and the globe all have something to
///   show, and removal takes exactly that history back out.
class StarterSeeder {
  StarterSeeder(this._db) : _ledger = XpLedgerService(_db);

  final AtlasDatabase _db;
  final XpLedgerService _ledger;
  static const _uuid = Uuid();

  static String seedId(String userId, String kind, int slot) =>
      _uuid.v5(Namespace.url.value, 'atlas:seed:$userId:$kind:$slot');

  // title, note, category, type, xp, hour (or null), done today
  static const _tasks = <(String, String, String, String, int, int?, bool)>[
    ('Reply to Sam', 'Before lunch', 'work', 'daily', 25, 11, true),
    ('Read 20 pages', 'Any book counts', 'learning', 'daily', 20, 21, false),
    ('Plan the week', 'Sunday ritual', 'mindfulness', 'weekly', 45, null, false),
    ('Book the dentist', 'Just the call', 'health', 'longTerm', 30, null, false),
  ];

  // title, category, reminder, last-7-days pattern (oldest first, today last)
  static const _habits = <(String, String, String?, List<int>)>[
    ('Move your body', 'fitness', '07:30', [1, 1, 1, 1, 1, 1, 1]),
    ('Drink enough water', 'health', null, [1, 1, 1, 0, 1, 1, 1]),
    ('Stretch for 10 minutes', 'fitness', null, [0, 1, 1, 1, 1, 1, 1]),
    ('Wind down before bed', 'mindfulness', '22:30', [1, 1, 0, 1, 1, 1, 0]),
    ('Rest properly tonight', 'health', '23:30', [0, 0, 1, 0, 0, 1, 0]),
  ];

  // title, category, progress, target in days (null = none)
  static const _goals = <(String, String, double, int?)>[
    ('Run a half marathon', 'fitness', .62, 42),
    ('Read 24 books this year', 'learning', .46, 180),
    ('Save for a trip', 'financial', .8, 18),
    ('Learn watercolor basics', 'creative', 1.0, null),
  ];

  // title, body, type, hours ago, read
  static const _notifications = <(String, String, String, int, bool)>[
    ('You discovered a new place', 'Pine Ridge is on your Atlas now.', 'systemMessage', 2, false),
    ('Your weekly letter is ready', 'Aurora wrote to you about your week.', 'systemMessage', 20, false),
    ('Gentle reminder', 'Winding down is waiting whenever you are.', 'habitReminder', 28, true),
    ('Twelve days in a row', 'You showed up twelve days running. That counts.', 'streakAlert', 50, true),
  ];

  /// Earlier days in the ledger: daily XP from the seeded daily tasks and
  /// habits, so Insights has a past (oldest first, 14 days before the last 7).
  static const _olderPattern = [3, 4, 2, 5, 4, 3, 5, 4, 2, 4, 5, 3, 4, 5];

  Future<void> seed(String userId) async {
    final now = DateTime.now();
    final today = dateOnly(now);
    await _db.transaction(() async {
      // Tasks.
      for (var i = 0; i < _tasks.length; i++) {
        final (title, note, cat, type, xp, hour, done) = _tasks[i];
        await _db.into(_db.tasks).insertOnConflictUpdate(TasksCompanion.insert(
              id: seedId(userId, 'task', i),
              userId: userId,
              title: title,
              description: Value(note),
              type: type,
              category: cat,
              xpReward: Value(xp),
              difficulty: Value(xp >= 40 ? 3 : (xp >= 25 ? 2 : 1)),
              dueDate: Value(hour == null
                  ? (type == 'weekly' ? addDays(startOfWeek(today), 6) : null)
                  : DateTime(today.year, today.month, today.day, hour)),
              isCompleted: Value(done),
              lastCompletedDate: Value(done ? now : null),
              createdAt: addDays(today, -21),
              updatedAt: now,
              isDirty: const Value(true),
              isDeleted: const Value(false),
              deletedAt: const Value(null),
            ));
      }

      // Habits, with honest streaks from their patterns.
      for (var i = 0; i < _habits.length; i++) {
        final (title, cat, time, pattern) = _habits[i];
        final doneToday = pattern.last == 1;
        var streak = 0;
        for (var d = pattern.length - 1; d >= 0; d--) {
          if (pattern[d] == 1) {
            streak++;
          } else if (d != pattern.length - 1) {
            break;
          }
        }
        if (i == 0) streak = 12; // the long-running one, as in the design
        final lastIdx = pattern.lastIndexOf(1);
        final last = lastIdx < 0 ? null : addDays(today, lastIdx - 6);
        await _db.into(_db.habits).insertOnConflictUpdate(HabitsCompanion.insert(
              id: seedId(userId, 'habit', i),
              userId: userId,
              title: title,
              category: cat,
              frequency: 'daily',
              difficulty: const Value(1),
              isCompletedToday: Value(doneToday),
              streakCount: Value(streak),
              longestStreak: Value(streak < 14 ? 14 : streak),
              totalCompletions: Value(pattern.where((p) => p == 1).length + 14),
              reminderTime: Value(time),
              lastCompletedDate: Value(last == null ? null : (doneToday ? now : last)),
              createdAt: addDays(today, -21),
              updatedAt: now,
              isDirty: const Value(true),
              isDeleted: const Value(false),
              deletedAt: const Value(null),
            ));
      }

      // Goals.
      for (var i = 0; i < _goals.length; i++) {
        final (title, cat, progress, days) = _goals[i];
        final done = progress >= 1;
        await _db.into(_db.goals).insertOnConflictUpdate(GoalsCompanion.insert(
              id: seedId(userId, 'goal', i),
              userId: userId,
              title: title,
              category: cat,
              priority: 'medium',
              status: done ? 'completed' : 'inProgress',
              progress: Value(progress),
              startDate: Value(addDays(today, -40)),
              deadline: Value(days == null ? null : addDays(today, days)),
              completedAt: Value(done ? addDays(today, -3) : null),
              createdAt: addDays(today, -40),
              updatedAt: now,
              isDirty: const Value(true),
              isDeleted: const Value(false),
              deletedAt: const Value(null),
            ));
      }

      // Notifications.
      for (var i = 0; i < _notifications.length; i++) {
        final (title, body, type, hours, read) = _notifications[i];
        final created = now.subtract(Duration(hours: hours));
        await _db.into(_db.notifications).insertOnConflictUpdate(NotificationsCompanion.insert(
              id: seedId(userId, 'notification', i),
              userId: userId,
              title: title,
              body: body,
              type: type,
              isRead: Value(read),
              readAt: Value(read ? created : null),
              createdAt: created,
              updatedAt: Value(now),
              isDirty: const Value(true),
              isDeleted: const Value(false),
              deletedAt: const Value(null),
            ));
      }
    });

    // History, through the same ledger the app writes (idempotent per item
    // per day, so seeding twice can't double it).
    for (final e in _historyItems(userId, today)) {
      await _ledger.record(
        userId: userId,
        itemKey: e.key,
        xp: e.xp,
        category: e.category,
        type: e.type,
        day: e.day,
      );
    }
  }

  /// Remove exactly what [seed] added, ledger history included. Rows are
  /// soft-deleted (tombstones, so the removal syncs), filtered by user.
  Future<void> remove(String userId) async {
    final now = DateTime.now();
    final today = dateOnly(now);
    for (final e in _historyItems(userId, today)) {
      await _ledger.revoke(
        userId: userId,
        itemKey: e.key,
        category: e.category,
        type: e.type,
        day: e.day,
      );
    }
    await _db.transaction(() async {
      for (var i = 0; i < _tasks.length; i++) {
        await (_db.update(_db.tasks)
              ..where((t) => t.id.equals(seedId(userId, 'task', i)) & t.userId.equals(userId)))
            .write(TasksCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ));
      }
      for (var i = 0; i < _habits.length; i++) {
        await (_db.update(_db.habits)
              ..where((h) => h.id.equals(seedId(userId, 'habit', i)) & h.userId.equals(userId)))
            .write(HabitsCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ));
      }
      for (var i = 0; i < _goals.length; i++) {
        await (_db.update(_db.goals)
              ..where((g) => g.id.equals(seedId(userId, 'goal', i)) & g.userId.equals(userId)))
            .write(GoalsCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ));
      }
      for (var i = 0; i < _notifications.length; i++) {
        await (_db.update(_db.notifications)
              ..where((n) =>
                  n.id.equals(seedId(userId, 'notification', i)) & n.userId.equals(userId)))
            .write(NotificationsCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ));
      }
    });
    await removeLegacy(userId);
  }

  /// Whether this user currently has (live) example content.
  Future<bool> hasSeed(String userId) async {
    final row = await (_db.select(_db.habits)
          ..where((h) =>
              h.id.equals(seedId(userId, 'habit', 0)) & h.isDeleted.equals(false)))
        .getSingleOrNull();
    return row != null;
  }

  /// Old builds seeded rows with ids like `seed-task-0`. The server never
  /// accepted them, so they exist only on this device: delete them outright.
  Future<void> removeLegacy(String userId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.tasks)..where((t) => t.id.like('seed-%') & t.userId.equals(userId))).go();
      await (_db.delete(_db.habits)..where((t) => t.id.like('seed-%') & t.userId.equals(userId))).go();
      await (_db.delete(_db.goals)..where((t) => t.id.like('seed-%') & t.userId.equals(userId))).go();
      await (_db.delete(_db.notifications)
            ..where((t) => t.id.like('seed-%') & t.userId.equals(userId)))
          .go();
      await (_db.delete(_db.progressEntries)
            ..where((t) => t.id.like('seed-%') & t.userId.equals(userId)))
          .go();
    });
  }

  /// Old builds' example rows can't sync (their ids aren't UUIDs). Give them
  /// proper ids once, so they behave like everything else.
  Future<void> migrateLegacyIds(String userId) async {
    var slot = 0;
    Future<void> rekey<T extends Table, R>(
      TableInfo<T, R> table,
      String kind,
      Expression<String> Function(T) idCol,
      Expression<String> Function(T) userCol,
    ) async {
      final rows = await (_db.select(table)
            ..where((t) => idCol(t).like('seed-%') & userCol(t).equals(userId)))
          .get();
      for (final r in rows) {
        final old = (r as dynamic).id as String;
        final fresh = seedId(userId, '$kind-legacy', slot++);
        await _db.customUpdate(
          'UPDATE ${table.actualTableName} SET id = ?, is_dirty = 1 WHERE id = ?',
          variables: [Variable.withString(fresh), Variable.withString(old)],
          updates: {table},
        );
      }
    }

    await rekey(_db.tasks, 'task', (t) => t.id, (t) => t.userId);
    await rekey(_db.habits, 'habit', (t) => t.id, (t) => t.userId);
    await rekey(_db.goals, 'goal', (t) => t.id, (t) => t.userId);
    await rekey(_db.notifications, 'notification', (t) => t.id, (t) => t.userId);

    // Legacy seeded progress rows become that day's ledger row (or merge
    // away if the day already has one).
    final progress = await (_db.select(_db.progressEntries)
          ..where((p) => p.id.like('seed-%') & p.userId.equals(userId)))
        .get();
    for (final p in progress) {
      final id = Ledger.entryId(userId, p.date);
      final clash = await (_db.select(_db.progressEntries)..where((x) => x.id.equals(id)))
          .getSingleOrNull();
      if (clash != null) {
        await (_db.delete(_db.progressEntries)..where((x) => x.id.equals(p.id))).go();
      } else {
        await _db.customUpdate(
          'UPDATE progress_entries SET id = ?, is_dirty = 1 WHERE id = ?',
          variables: [Variable.withString(id), Variable.withString(p.id)],
          updates: {_db.progressEntries},
        );
      }
    }
  }

  List<_Item> _historyItems(String userId, DateTime today) {
    final items = <_Item>[];
    // Last 7 days of habits, per pattern.
    for (var h = 0; h < _habits.length; h++) {
      final (_, cat, _, pattern) = _habits[h];
      for (var d = 0; d < 7; d++) {
        if (pattern[d] != 1) continue;
        final day = addDays(today, d - 6);
        items.add(_Item(
          Ledger.habitKey(seedId(userId, 'habit', h)),
          GamificationConstants.calculateHabitXp(difficulty: 1, streakCount: d + 5),
          cat,
          'habit',
          day,
        ));
      }
    }
    // Today's done task.
    for (var t = 0; t < _tasks.length; t++) {
      final (_, _, cat, type, xp, _, done) = _tasks[t];
      if (done) items.add(_Item(Ledger.taskKey(seedId(userId, 'task', t)), xp, cat, type, today));
    }
    // Two earlier weeks: daily tasks and habits, a different mix each day.
    for (var d = 0; d < _olderPattern.length; d++) {
      final day = addDays(today, d - 20);
      final n = _olderPattern[d];
      for (var h = 0; h < n && h < _habits.length; h++) {
        items.add(_Item(Ledger.habitKey(seedId(userId, 'habit', h)), 12, _habits[h].$2, 'habit', day));
      }
      for (var t = 0; t < 2; t++) {
        if ((d + t) % 3 == 0) continue;
        final (_, _, cat, type, xp, _, _) = _tasks[t];
        items.add(_Item(Ledger.taskKey(seedId(userId, 'task', t)), xp * 3, cat, type, day));
      }
    }
    return items;
  }
}

class _Item {
  const _Item(this.key, this.xp, this.category, this.type, this.day);
  final String key;
  final int xp;
  final String category;
  final String type;
  final DateTime day;
}
