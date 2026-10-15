import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/core/gamification/days.dart';

/// The local XP ledger: one record per user per local day, stored in the
/// synced ProgressEntries table (no schema change).
///
/// - `xpGained` = XP earned that day; `tasksCompleted` = things tended.
/// - `categoryBreakdown` = {category: xp}.
/// - `taskTypeBreakdown` = {"habit" | "daily" | "weekly" | "long_term" |
///   "goal": count}.
/// - `additionalMetrics` = `{"h:habitId" | "t:taskId" | "g:goalId": xp}`,
///   one key per completed item. This is what powers sparklines, week rings,
///   insights and exact undo.
///
/// Ids are deterministic (UUID v5 of user + day), so two devices write the
/// same row for the same day and sync merges instead of duplicating.
class Ledger {
  Ledger._();

  static const _uuid = Uuid();

  static String entryId(String userId, DateTime day) =>
      _uuid.v5(Namespace.url.value, 'atlas:progress:$userId:${dayKey(day)}');

  static String habitKey(String id) => 'h:$id';
  static String taskKey(String id) => 't:$id';
  static String goalKey(String id) => 'g:$id';
}

/// One parsed day of the ledger.
class LedgerDay {
  LedgerDay({
    required this.date,
    required this.xp,
    required this.count,
    required this.items,
    required this.categories,
    required this.types,
  });

  final DateTime date;
  final int xp;
  final int count;

  /// itemKey → XP earned for it that day.
  final Map<String, int> items;
  final Map<String, int> categories;
  final Map<String, int> types;

  bool has(String itemKey) => items.containsKey(itemKey);

  static LedgerDay parse({
    required DateTime date,
    required int xp,
    required int count,
    String? categoryBreakdown,
    String? taskTypeBreakdown,
    String? additionalMetrics,
  }) =>
      LedgerDay(
        date: dateOnly(date),
        xp: xp,
        count: count,
        items: decodeIntMap(additionalMetrics),
        categories: decodeIntMap(categoryBreakdown),
        types: decodeIntMap(taskTypeBreakdown),
      );

  /// Tolerant JSON → `Map<String,int>` (values may arrive as doubles from
  /// the server; anything malformed is ignored).
  static Map<String, int> decodeIntMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final v = jsonDecode(raw);
      if (v is! Map) return {};
      final out = <String, int>{};
      v.forEach((k, val) {
        if (val is num) out['$k'] = val.round();
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  static String encode(Map<String, int> m) => jsonEncode(m);
}

/// Where a total of XP sits on the level curve.
class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.totalXp,
    required this.floor,
    required this.ceil,
  });

  final int level;
  final int totalXp;

  /// XP at which [level] started and [level]+1 starts.
  final int floor;
  final int ceil;

  int get xpInLevel => totalXp - floor;
  int get xpForLevel => ceil - floor;
  int get xpToNext => (ceil - totalXp).clamp(0, 1 << 30);
  double get fraction =>
      xpForLevel <= 0 ? 1 : (xpInLevel / xpForLevel).clamp(0.0, 1.0);

  /// The one shared helper for level math (Home, Profile, level-up). Uses the
  /// real quadratic curve in [GamificationConstants.xpRequiredForLevel].
  static LevelInfo of(int totalXp) {
    final xp = totalXp < 0 ? 0 : totalXp;
    final level = GamificationConstants.calculateLevel(xp);
    final floor = GamificationConstants.xpRequiredForLevel(level);
    final ceil = level >= GamificationConstants.maxLevel
        ? floor
        : GamificationConstants.xpRequiredForLevel(level + 1);
    return LevelInfo(level: level, totalXp: xp, floor: floor, ceil: ceil);
  }
}

/// Derived numbers from the ledger. Pure, so it is easy to test.
class LedgerMath {
  LedgerMath._();

  static int totalXp(Iterable<LedgerDay> days) =>
      days.fold(0, (s, d) => s + (d.xp > 0 ? d.xp : 0));

  static LedgerDay? dayOf(Iterable<LedgerDay> days, DateTime day) {
    for (final d in days) {
      if (isSameDay(d.date, day)) return d;
    }
    return null;
  }

  /// Days you showed up in a row, ending today, or yesterday if today has
  /// nothing yet (so the streak doesn't "break" at midnight).
  static int currentStreak(Iterable<LedgerDay> days, DateTime today) {
    final active = {
      for (final d in days)
        if (d.xp > 0 || d.count > 0) dayKey(d.date),
    };
    var cursor = dateOnly(today);
    if (!active.contains(dayKey(cursor))) cursor = addDays(cursor, -1);
    var n = 0;
    while (active.contains(dayKey(cursor))) {
      n++;
      cursor = addDays(cursor, -1);
    }
    return n;
  }

  static int longestStreak(Iterable<LedgerDay> days) {
    final dates = {
      for (final d in days)
        if (d.xp > 0 || d.count > 0) dateOnly(d.date),
    }.toList()
      ..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in dates) {
      run = (prev != null && daysBetween(prev, d) == 1) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  /// Whether [itemKey] was completed on each of the 7 days ending [today]
  /// (oldest first).
  static List<bool> last7(Iterable<LedgerDay> days, String itemKey, DateTime today) {
    final byKey = {for (final d in days) dayKey(d.date): d};
    return [
      for (var i = 6; i >= 0; i--)
        byKey[dayKey(addDays(today, -i))]?.has(itemKey) ?? false,
    ];
  }

  /// The most recent day before [before] on which [itemKey] was completed.
  static DateTime? lastCompletionBefore(
      Iterable<LedgerDay> days, String itemKey, DateTime before) {
    DateTime? best;
    for (final d in days) {
      if (!d.has(itemKey) || !d.date.isBefore(dateOnly(before))) continue;
      if (best == null || d.date.isAfter(best)) best = d.date;
    }
    return best;
  }
}

/// When a habit is due. Daily habits are due every day; weekly ones once per
/// ISO week; weekdays / weekends on those days only.
class HabitSchedule {
  HabitSchedule._();

  static bool isWeekly(String frequency) => frequency.toLowerCase() == 'weekly';

  static bool isScheduledOn(String frequency, DateTime day) {
    switch (frequency.toLowerCase()) {
      case 'weekdays':
        return day.weekday <= 5;
      case 'weekends':
        return day.weekday >= 6;
      default:
        return true;
    }
  }

  /// Whether a completion at [last] still counts as "done" in the period
  /// containing [today].
  static bool doneInPeriod(String frequency, DateTime? last, DateTime today) {
    if (last == null) return false;
    if (isWeekly(frequency)) {
      return !dateOnly(last).isBefore(startOfWeek(today));
    }
    return isSameDay(last, today);
  }

  /// The previous due period's start before [today] (yesterday for daily,
  /// last Monday's week for weekly, the previous scheduled day otherwise).
  static DateTime previousDue(String frequency, DateTime today) {
    if (isWeekly(frequency)) return addDays(startOfWeek(today), -7);
    var d = addDays(dateOnly(today), -1);
    for (var i = 0; i < 7 && !isScheduledOn(frequency, d); i++) {
      d = addDays(d, -1);
    }
    return d;
  }

  /// Whether the streak is still alive given the last completion: done in
  /// this period or the previous due one.
  static bool streakAlive(String frequency, DateTime? last, DateTime today) {
    if (last == null) return false;
    if (doneInPeriod(frequency, last, today)) return true;
    final prev = previousDue(frequency, today);
    if (isWeekly(frequency)) return !dateOnly(last).isBefore(prev);
    return !dateOnly(last).isBefore(prev);
  }

  /// The streak after completing now, given the last completion.
  static int nextStreak(String frequency, DateTime? last, int streak, DateTime today) {
    if (doneInPeriod(frequency, last, today)) return streak;
    return streakAlive(frequency, last, today) ? streak + 1 : 1;
  }
}

/// When a task comes back. Daily tasks recur each day, weekly ones each ISO
/// week; long-term tasks stay done.
class TaskSchedule {
  TaskSchedule._();

  static bool doneInPeriod(String type, DateTime? last, DateTime today) {
    if (last == null) return false;
    switch (type) {
      case 'daily':
        return isSameDay(last, today);
      case 'weekly':
        return !dateOnly(last).isBefore(startOfWeek(today));
      default:
        return true;
    }
  }
}
