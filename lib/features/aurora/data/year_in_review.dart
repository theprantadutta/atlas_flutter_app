import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/check_in_dao.dart';
import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';

/// A habit and how many days it was tended in the year.
class YearHabit {
  const YearHabit({required this.id, required this.title, required this.completions});
  final String id;
  final String title;
  final int completions;
}

/// "Your year": computed on the device from Drift. No AI, free for everyone.
class YearInReview {
  const YearInReview({
    required this.year,
    required this.daysTended,
    required this.totalXp,
    required this.longestStreak,
    required this.topHabits,
    required this.bestMonth,
    required this.bestMonthXp,
    required this.placesDiscovered,
    required this.moodSplit,
  });

  final int year;

  /// Local days with anything tended.
  final int daysTended;
  final int totalXp;

  /// Longest run of consecutive tended days inside the year.
  final int longestStreak;

  /// Up to 3, most completions first.
  final List<YearHabit> topHabits;

  /// 1 to 12, the month with the most XP; null when nothing was earned.
  final int? bestMonth;
  final int bestMonthXp;

  /// World tiles discovered (unlocked) during the year.
  final int placesDiscovered;

  /// mood (1 to 5) to number of check-ins; empty when there were none.
  final Map<int, int> moodSplit;

  bool get hasMoods => moodSplit.isNotEmpty;
  bool get isEmpty => daysTended == 0 && placesDiscovered == 0 && !hasMoods;

  /// Whether the "Your year" entry is promoted (from December 1st).
  static bool inSeason(DateTime now) => now.month == 12;

  /// Builds the review of [year] for [userId].
  static Future<YearInReview> compute(
      AtlasDatabase db, String userId, int year) async {
    final start = DateTime(year);
    final end = DateTime(year + 1);

    final entries = await (db.select(db.progressEntries)
          ..where((p) =>
              p.userId.equals(userId) &
              p.isDeleted.equals(false) &
              p.date.isBiggerOrEqualValue(start) &
              p.date.isSmallerThanValue(end)))
        .get();
    // One ledger day per local day (merge legacy duplicates).
    final byDay = <String, LedgerDay>{};
    for (final e in entries) {
      final d = LedgerDay.parse(
        date: e.date,
        xp: e.xpGained,
        count: e.tasksCompleted,
        categoryBreakdown: e.categoryBreakdown,
        taskTypeBreakdown: e.taskTypeBreakdown,
        additionalMetrics: e.additionalMetrics,
      );
      final k = dayKey(d.date);
      final prev = byDay[k];
      byDay[k] = prev == null
          ? d
          : LedgerDay(
              date: d.date,
              xp: prev.xp + d.xp,
              count: prev.count + d.count,
              items: {...prev.items, ...d.items},
              categories: prev.categories,
              types: prev.types,
            );
    }
    final days = byDay.values.toList();

    final tended = days.where((d) => d.xp > 0 || d.count > 0).length;
    final totalXp = LedgerMath.totalXp(days);
    final longest = LedgerMath.longestStreak(days);

    // Months by XP.
    final monthXp = <int, int>{};
    for (final d in days) {
      if (d.xp > 0) monthXp[d.date.month] = (monthXp[d.date.month] ?? 0) + d.xp;
    }
    int? bestMonth;
    var bestXp = 0;
    for (final e in monthXp.entries) {
      if (e.value > bestXp || (e.value == bestXp && bestMonth != null && e.key < bestMonth)) {
        bestMonth = e.key;
        bestXp = e.value;
      }
    }

    // Habit completions from the ledger keys ("h:<id>").
    final counts = <String, int>{};
    for (final d in days) {
      for (final key in d.items.keys) {
        if (key.startsWith('h:')) {
          final id = key.substring(2);
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
    }
    final habits = counts.isEmpty
        ? const <Habit>[]
        : await (db.select(db.habits)
              ..where((h) => h.userId.equals(userId) & h.id.isIn(counts.keys)))
            .get();
    final titles = {for (final h in habits) h.id: h.title};
    final ranked = [
      for (final e in counts.entries)
        if (titles[e.key] case final title?)
          YearHabit(id: e.key, title: title, completions: e.value),
    ]..sort((a, b) {
        final c = b.completions.compareTo(a.completions);
        return c != 0 ? c : a.title.compareTo(b.title);
      });

    // Places discovered in the year.
    final tiles = await (db.select(db.worldTiles)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isDeleted.equals(false) &
              t.isUnlocked.equals(true)))
        .get();
    final places = tiles.where((t) {
      final at = t.unlockedAt ?? t.createdAt;
      return !at.isBefore(start) && at.isBefore(end);
    }).length;

    // Mood split.
    final checkIns = CheckInRepository.onePerMoment(
        await CheckInDao(db).getRange(userId, start, end));
    final moods = <int, int>{};
    for (final c in checkIns) {
      moods[c.mood] = (moods[c.mood] ?? 0) + 1;
    }

    return YearInReview(
      year: year,
      daysTended: tended,
      totalXp: totalXp,
      longestStreak: longest,
      topHabits: ranked.take(3).toList(),
      bestMonth: bestMonth,
      bestMonthXp: bestXp,
      placesDiscovered: places,
      moodSplit: moods,
    );
  }
}
