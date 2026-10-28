import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/check_in_dao.dart';
import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';

/// Which window the `week` / `month` block of the context covers.
enum AuroraContextPeriod {
  /// The last 7 local days, ending today. Sent with chat, check-in, plan-day,
  /// goal-steps and weekly letters.
  week,

  /// The last 30 local days, ending today. Sent with monthly letters.
  month,
}

/// What Aurora knows about the user's day, built on the device from Drift and
/// sent with every Aurora request as `context` (see COMPANION_SPEC section 1).
///
/// The server usually has none of this (sync is premium and off for most
/// users). Every cap here is also enforced on the server.
class AuroraContextBuilder {
  AuroraContextBuilder(this._db);

  final AtlasDatabase _db;

  // Caps (shared with the server).
  static const maxHabits = 30;
  static const maxTasks = 30;
  static const maxGoals = 15;
  static const maxMemories = 20;
  static const maxMonthMoods = 31;

  /// 7 days, morning and evening.
  static const maxWeekMoods = 14;
  static const maxTitle = 80;
  static const maxNote = 200;
  static const maxMemory = 200;

  /// Builds the wire `context` map.
  ///
  /// [includeMemories] must only be true when the user is premium on the
  /// device. [now] defaults to the clock.
  Future<Map<String, dynamic>> build({
    required String userId,
    required bool includeMemories,
    AuroraContextPeriod period = AuroraContextPeriod.week,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final today = dateOnly(at);
    final windowDays = period == AuroraContextPeriod.month ? 30 : 7;
    final windowStart = addDays(today, -(windowDays - 1));
    final tomorrow = addDays(today, 1);

    final ledger = await _ledgerDays(userId, windowStart, tomorrow);

    final habits = await _habits(userId, ledger, today);
    final tasks = await _tasks(userId, today);
    final goals = await _goals(userId);
    final totals = _totals(ledger, windowStart, today, period);
    final moods = await _moods(userId, windowStart, tomorrow, period);

    return {
      'today': dayKey(today),
      'weekday': weekdayName(today),
      'local_time': formatHm(at.hour, at.minute),
      'habits': habits,
      'tasks': tasks,
      'goals': goals,
      period == AuroraContextPeriod.month ? 'month' : 'week': totals,
      'moods': moods,
      if (includeMemories) 'memories': await _memories(userId),
    };
  }

  // ─── Pieces ─────────────────────────────────────────────────────────

  Future<List<LedgerDay>> _ledgerDays(
      String userId, DateTime start, DateTime end) async {
    final rows = await (_db.select(_db.progressEntries)
          ..where((p) =>
              p.userId.equals(userId) &
              p.isDeleted.equals(false) &
              p.date.isBiggerOrEqualValue(start) &
              p.date.isSmallerThanValue(end)))
        .get();
    return [
      for (final e in rows)
        LedgerDay.parse(
          date: e.date,
          xp: e.xpGained,
          count: e.tasksCompleted,
          categoryBreakdown: e.categoryBreakdown,
          taskTypeBreakdown: e.taskTypeBreakdown,
          additionalMetrics: e.additionalMetrics,
        ),
    ];
  }

  Future<List<Map<String, dynamic>>> _habits(
      String userId, List<LedgerDay> ledger, DateTime today) async {
    final rows = await (_db.select(_db.habits)
          ..where((h) => h.userId.equals(userId) & h.isDeleted.equals(false))
          ..orderBy([(h) => OrderingTerm.asc(h.createdAt)]))
        .get();
    final items = [
      for (final h in rows)
        if (HabitSchedule.doneInPeriod(h.frequency, h.lastCompletedDate, today)
            case final done)
        (
          done: done,
          json: <String, dynamic>{
            'id': h.id,
            'title': cleanForPrompt(h.title, maxTitle),
            'category': h.category,
            'frequency': h.frequency,
            'done_today': done,
            // A streak that has lapsed is 0, not the stale stored number.
            'streak':
                HabitSchedule.streakAlive(h.frequency, h.lastCompletedDate, today)
                    ? h.streakCount
                    : 0,
            'done_last_7': LedgerMath.last7(ledger, Ledger.habitKey(h.id), today)
                .where((d) => d)
                .length,
          },
        ),
    ];
    // Still to do first, then done; stable within each group.
    return [
      ...items.where((i) => !i.done).map((i) => i.json),
      ...items.where((i) => i.done).map((i) => i.json),
    ].take(maxHabits).toList();
  }

  Future<List<Map<String, dynamic>>> _tasks(
      String userId, DateTime today) async {
    final rows = await (_db.select(_db.tasks)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    Map<String, dynamic> wire(Task t, bool done) => {
          'id': t.id,
          'title': cleanForPrompt(t.title, maxTitle),
          'type': t.type,
          'category': t.category,
          'done': done,
        };
    final open = <Map<String, dynamic>>[];
    final doneToday = <Map<String, dynamic>>[];
    for (final t in rows) {
      final done = t.isCompleted &&
          TaskSchedule.doneInPeriod(t.type, t.lastCompletedDate, today);
      if (!done) {
        open.add(wire(t, false));
      } else if (t.lastCompletedDate != null &&
          isSameDay(t.lastCompletedDate!, today)) {
        doneToday.add(wire(t, true));
      }
      // Done on an earlier day (a weekly or long-term task): not today's news.
    }
    return [...open, ...doneToday].take(maxTasks).toList();
  }

  Future<List<Map<String, dynamic>>> _goals(String userId) async {
    final rows = await (_db.select(_db.goals)
          ..where((g) =>
              g.userId.equals(userId) &
              g.isDeleted.equals(false) &
              g.status.isNotIn(const ['completed', 'cancelled']))
          ..orderBy([(g) => OrderingTerm.asc(g.createdAt)]))
        .get();
    return [
      for (final g in rows.take(maxGoals))
        {
          'id': g.id,
          'title': cleanForPrompt(g.title, maxTitle),
          'category': g.category,
          'progress': normaliseProgress(g.progress),
          'target_date': g.deadline == null ? null : dayKey(g.deadline!),
        },
    ];
  }

  Map<String, dynamic> _totals(List<LedgerDay> ledger, DateTime start,
      DateTime today, AuroraContextPeriod period) {
    var xp = 0;
    var tended = 0;
    LedgerDay? best;
    final byCategory = <String, int>{};
    for (final d in ledger) {
      if (d.date.isBefore(start) || d.date.isAfter(today)) continue;
      if (d.xp > 0) xp += d.xp;
      if (d.xp > 0 || d.count > 0) tended++;
      if (d.xp > 0 && (best == null || d.xp > best.xp)) best = d;
      d.categories.forEach((k, v) {
        if (v > 0) byCategory[k] = (byCategory[k] ?? 0) + v;
      });
    }
    final cats = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {
      'xp': xp,
      'tended_days': tended,
      // A weekday name for the week ("Monday"); over a month a weekday is
      // ambiguous, so the day itself ("2026-10-12").
      'best_day': best == null
          ? null
          : period == AuroraContextPeriod.month
              ? dayKey(best.date)
              : weekdayName(best.date),
      'by_category': [
        for (final c in cats) {'category': c.key, 'xp': c.value},
      ],
    };
  }

  Future<List<Map<String, dynamic>>> _moods(String userId, DateTime start,
      DateTime end, AuroraContextPeriod period) async {
    // One per (day, moment), oldest first, morning before evening.
    var rows = CheckInRepository.onePerMoment(
        await CheckInDao(_db).getRange(userId, start, end));
    final cap =
        period == AuroraContextPeriod.month ? maxMonthMoods : maxWeekMoods;
    if (rows.length > cap) rows = rows.sublist(rows.length - cap);
    return [
      for (final c in rows)
        {
          'date': dayKey(c.date),
          'moment': c.moment,
          'mood': c.mood,
          'note': switch (c.note) {
            final n? when n.trim().isNotEmpty => cleanForPrompt(n, maxNote),
            _ => null,
          },
        },
    ];
  }

  Future<List<String>> _memories(String userId) async {
    final rows = await (_db.select(_db.auroraMemories)
          ..where((m) => m.userId.equals(userId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
          ..limit(maxMemories))
        .get();
    return [
      for (final m in rows)
        if (m.content.trim().isNotEmpty) cleanForPrompt(m.content, maxMemory),
    ];
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  /// Like the server's `AuroraVoice.Clean`: control characters to spaces,
  /// double quotes to single, whitespace collapsed, capped at [max] chars.
  static String cleanForPrompt(String raw, int max) {
    var s = raw
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll('"', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (s.length > max) s = s.substring(0, max).trimRight();
    return s;
  }

  /// Goal progress as 0 to 1 (tolerates a 0 to 100 value).
  static double normaliseProgress(double p) {
    final v = p > 1 ? p / 100 : p;
    return double.parse(v.clamp(0.0, 1.0).toStringAsFixed(2));
  }
}
