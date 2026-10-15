import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/services/xp_ledger_service.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/progress/providers/progress_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

// ─── Today ──────────────────────────────────────────────────────────

/// The current local date. Ticks over at midnight (and is refreshed on app
/// resume), so everything that depends on "today" rolls over by itself.
class TodayNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    final today = dateOnly(DateTime.now());
    _schedule(today);
    return today;
  }

  void _schedule(DateTime today) {
    _timer?.cancel();
    final next = addDays(today, 1);
    // A second past midnight, so DateTime.now() is safely on the new day.
    final wait = next.difference(DateTime.now()) + const Duration(seconds: 1);
    _timer = Timer(wait, refresh);
  }

  /// Re-read the clock (call on app resume).
  void refresh() {
    final today = dateOnly(DateTime.now());
    if (!isSameDay(today, state)) state = today;
    _schedule(today);
  }
}

final todayProvider = NotifierProvider<TodayNotifier, DateTime>(TodayNotifier.new);

// ─── Ledger ─────────────────────────────────────────────────────────

final xpLedgerServiceProvider = Provider<XpLedgerService>(
  (ref) => XpLedgerService(ref.read(databaseProvider)),
);

/// The parsed ledger, most recent day first.
final ledgerDaysProvider = Provider.autoDispose<List<LedgerDay>>((ref) {
  final entries =
      ref.watch(progressEntriesStreamProvider).value ?? const <ProgressEntry>[];
  return [
    for (final e in entries)
      LedgerDay.parse(
        date: e.date,
        xp: e.xpGained,
        count: e.tasksCompleted,
        categoryBreakdown: e.categoryBreakdown,
        taskTypeBreakdown: e.taskTypeBreakdown,
        additionalMetrics: e.additionalMetrics,
      ),
  ];
});

/// The numbers every screen shows about the player, from the local ledger.
class PlayerStats {
  const PlayerStats({
    required this.totalXp,
    required this.level,
    required this.streak,
    required this.bestStreak,
    required this.xpToday,
    required this.tendedToday,
  });

  final int totalXp;
  final LevelInfo level;
  final int streak;
  final int bestStreak;
  final int xpToday;
  final int tendedToday;

  static final empty = PlayerStats(
    totalXp: 0,
    level: LevelInfo.of(0),
    streak: 0,
    bestStreak: 0,
    xpToday: 0,
    tendedToday: 0,
  );
}

final playerStatsProvider = Provider.autoDispose<PlayerStats>((ref) {
  final days = ref.watch(ledgerDaysProvider);
  final today = ref.watch(todayProvider);
  final user = ref.watch(authProvider.select((s) => s.user));
  final local = LedgerMath.totalXp(days);
  // The ledger is the source of truth. A legacy account whose XP predates
  // the ledger (and was never synced down) keeps its server total.
  final total = local > (user?.totalXp ?? 0) ? local : (user?.totalXp ?? 0);
  final todayDay = LedgerMath.dayOf(days, today);
  final streak = LedgerMath.currentStreak(days, today);
  final best = LedgerMath.longestStreak(days);
  return PlayerStats(
    totalXp: total,
    level: LevelInfo.of(total),
    streak: streak,
    bestStreak: best > (user?.longestStreak ?? 0) ? best : (user?.longestStreak ?? 0),
    xpToday: todayDay?.xp ?? 0,
    tendedToday: todayDay?.count ?? 0,
  );
});

// ─── Tending ────────────────────────────────────────────────────────

/// What a tend did, so the UI can celebrate (and undo) precisely.
class TendOutcome {
  const TendOutcome({
    required this.xp,
    required this.itemKey,
    required this.undo,
    this.leveledUpTo,
  });

  final int xp;
  final String itemKey;

  /// Reverses everything this tend did (completion, streak, XP).
  final Future<void> Function() undo;

  /// The new level, if this tend crossed a level boundary.
  final int? leveledUpTo;
}

final tendControllerProvider = Provider<TendController>((ref) => TendController(ref));

/// Completing and un-completing things. Every path writes the item and the
/// ledger locally, marks rows dirty, and keeps streaks honest.
class TendController {
  TendController(this._ref);
  final Ref _ref;

  AtlasDatabase get _db => _ref.read(databaseProvider);
  XpLedgerService get _ledger => _ref.read(xpLedgerServiceProvider);
  String get _userId => _ref.read(currentUserIdProvider);

  int _totalXp() {
    try {
      return _ref.read(playerStatsProvider).totalXp;
    } catch (_) {
      return 0;
    }
  }

  int? _levelUp(int before, int after) {
    final a = LevelInfo.of(before).level, b = LevelInfo.of(after).level;
    return b > a ? b : null;
  }

  // ── Tasks ──

  Future<TendOutcome?> tendTask(Task task) async {
    final today = dateOnly(DateTime.now());
    if (task.isCompleted && TaskSchedule.doneInPeriod(task.type, task.lastCompletedDate, today)) {
      return null;
    }
    final before = _totalXp();
    final now = DateTime.now();
    final prev = (task.isCompleted, task.lastCompletedDate, task.streakCount);
    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(TasksCompanion(
      isCompleted: const Value(true),
      lastCompletedDate: Value(now),
      streakCount: Value(task.streakCount + 1),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
    final key = Ledger.taskKey(task.id);
    final xp = task.xpReward;
    await _ledger.record(
      userId: _userId,
      itemKey: key,
      xp: xp,
      category: task.category,
      type: _taskType(task.type),
      level: LevelInfo.of(before + xp).level,
    );
    return TendOutcome(
      xp: xp,
      itemKey: key,
      leveledUpTo: _levelUp(before, before + xp),
      undo: () async {
        await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(TasksCompanion(
          isCompleted: Value(prev.$1),
          lastCompletedDate: Value(prev.$2),
          streakCount: Value(prev.$3),
          updatedAt: Value(DateTime.now()),
          isDirty: const Value(true),
        ));
        await _ledger.revoke(
          userId: _userId,
          itemKey: key,
          category: task.category,
          type: _taskType(task.type),
          day: today,
        );
      },
    );
  }

  /// Un-complete a task that was completed earlier (e.g. unticked in Grow).
  Future<void> untendTask(Task task) async {
    final now = DateTime.now();
    final last = task.lastCompletedDate;
    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(TasksCompanion(
      isCompleted: const Value(false),
      lastCompletedDate: const Value(null),
      streakCount: Value((task.streakCount - 1).clamp(0, 1 << 30)),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
    await _ledger.revoke(
      userId: _userId,
      itemKey: Ledger.taskKey(task.id),
      category: task.category,
      type: _taskType(task.type),
      day: last ?? now,
    );
  }

  // ── Habits ──

  Future<TendOutcome?> tendHabit(Habit habit) async {
    final today = dateOnly(DateTime.now());
    if (habit.isCompletedToday &&
        HabitSchedule.doneInPeriod(habit.frequency, habit.lastCompletedDate, today)) {
      return null;
    }
    final before = _totalXp();
    final now = DateTime.now();
    final streak = HabitSchedule.nextStreak(
        habit.frequency, habit.lastCompletedDate, habit.streakCount, today);
    final longest = streak > habit.longestStreak ? streak : habit.longestStreak;
    final xp = GamificationConstants.calculateHabitXp(
      difficulty: habit.difficulty,
      streakCount: streak - 1,
    );
    final prev = habit;
    await (_db.update(_db.habits)..where((h) => h.id.equals(habit.id))).write(HabitsCompanion(
      isCompletedToday: const Value(true),
      streakCount: Value(streak),
      longestStreak: Value(longest),
      totalCompletions: Value(habit.totalCompletions + 1),
      lastCompletedDate: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
    final key = Ledger.habitKey(habit.id);
    await _ledger.record(
      userId: _userId,
      itemKey: key,
      xp: xp,
      category: habit.category,
      type: 'habit',
      streakCount: streak,
      level: LevelInfo.of(before + xp).level,
    );
    return TendOutcome(
      xp: xp,
      itemKey: key,
      leveledUpTo: _levelUp(before, before + xp),
      undo: () async {
        await (_db.update(_db.habits)..where((h) => h.id.equals(habit.id))).write(HabitsCompanion(
          isCompletedToday: Value(prev.isCompletedToday),
          streakCount: Value(prev.streakCount),
          longestStreak: Value(prev.longestStreak),
          totalCompletions: Value(prev.totalCompletions),
          lastCompletedDate: Value(prev.lastCompletedDate),
          updatedAt: Value(DateTime.now()),
          isDirty: const Value(true),
        ));
        await _ledger.revoke(
          userId: _userId,
          itemKey: key,
          category: habit.category,
          type: 'habit',
          day: today,
        );
      },
    );
  }

  /// Un-complete today's check-in without a snapshot (a plain untick).
  /// The previous completion date is recovered from the ledger, so the
  /// streak and "last done" stay truthful.
  Future<void> untendHabit(Habit habit, List<LedgerDay> days) async {
    final today = dateOnly(DateTime.now());
    final key = Ledger.habitKey(habit.id);
    final prevDate = LedgerMath.lastCompletionBefore(days, key, today);
    final streak = (habit.streakCount - 1).clamp(0, 1 << 30);
    final longest = habit.longestStreak == habit.streakCount && habit.longestStreak > streak
        ? (habit.longestStreak - 1).clamp(streak, 1 << 30)
        : habit.longestStreak;
    await (_db.update(_db.habits)..where((h) => h.id.equals(habit.id))).write(HabitsCompanion(
      isCompletedToday: const Value(false),
      streakCount: Value(streak),
      longestStreak: Value(longest),
      totalCompletions: Value((habit.totalCompletions - 1).clamp(0, 1 << 30)),
      lastCompletedDate: Value(prevDate),
      updatedAt: Value(DateTime.now()),
      isDirty: const Value(true),
    ));
    await _ledger.revoke(
      userId: _userId,
      itemKey: key,
      category: habit.category,
      type: 'habit',
      day: habit.lastCompletedDate ?? today,
    );
  }

  // ── Goals ──

  /// Move a goal's progress to [progress] (0..1). Crossing 100% awards the
  /// goal's XP once; dropping back below revokes it.
  Future<TendOutcome?> setGoalProgress(Goal goal, double progress) async {
    final next = progress.clamp(0.0, 1.0);
    final wasDone = goal.progress >= 1.0;
    final isDone = next >= 1.0;
    final now = DateTime.now();
    final before = _totalXp();
    await (_db.update(_db.goals)..where((g) => g.id.equals(goal.id))).write(GoalsCompanion(
      progress: Value(next),
      status: Value(isDone ? 'completed' : (next <= 0 ? 'notStarted' : 'inProgress')),
      // Keep the original completion date when already complete.
      completedAt: isDone ? Value(wasDone ? goal.completedAt ?? now : now) : const Value(null),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
    final key = Ledger.goalKey(goal.id);
    if (isDone && !wasDone) {
      final xp = GamificationConstants.calculateGoalXp(priority: _priority(goal.priority));
      await _ledger.record(
        userId: _userId,
        itemKey: key,
        xp: xp,
        category: goal.category,
        type: 'goal',
        level: LevelInfo.of(before + xp).level,
      );
      return TendOutcome(
        xp: xp,
        itemKey: key,
        leveledUpTo: _levelUp(before, before + xp),
        undo: () => setGoalProgress(goal.copyWith(progress: 1.0, completedAt: Value(now)), goal.progress),
      );
    }
    if (wasDone && !isDone) {
      await _ledger.revoke(
        userId: _userId,
        itemKey: key,
        category: goal.category,
        type: 'goal',
        day: goal.completedAt ?? now,
      );
    }
    return null;
  }

  static int _priority(String p) => switch (p.toLowerCase()) {
        'low' => 1,
        'high' => 3,
        'critical' => 4,
        _ => 2,
      };

  static String _taskType(String t) => switch (t) {
        'longTerm' || 'long_term' => 'long_term',
        'weekly' => 'weekly',
        _ => 'daily',
      };
}

// ─── Daily rollover ─────────────────────────────────────────────────

/// Clears "done" flags whose period has ended: habits that were done on an
/// earlier day (or week, for weekly habits) and recurring daily / weekly
/// tasks. Streaks that lapsed are set to 0. These are derived flags, so the
/// rows are not marked dirty and `updatedAt` is untouched: this never makes
/// sync churn, and the server's copy can't override it.
Future<void> runDailyRollover(AtlasDatabase db, String userId, DateTime today) async {
  final habits = await (db.select(db.habits)
        ..where((h) => h.userId.equals(userId) & h.isDeleted.equals(false)))
      .get();
  for (final h in habits) {
    final done = HabitSchedule.doneInPeriod(h.frequency, h.lastCompletedDate, today);
    final alive = HabitSchedule.streakAlive(h.frequency, h.lastCompletedDate, today);
    final resetDone = h.isCompletedToday && !done;
    final resetStreak = h.streakCount > 0 && !alive;
    if (!resetDone && !resetStreak) continue;
    await (db.update(db.habits)..where((r) => r.id.equals(h.id))).write(HabitsCompanion(
      isCompletedToday: resetDone ? const Value(false) : const Value.absent(),
      streakCount: resetStreak ? const Value(0) : const Value.absent(),
    ));
  }

  final tasks = await (db.select(db.tasks)
        ..where((t) =>
            t.userId.equals(userId) & t.isDeleted.equals(false) & t.isCompleted.equals(true)))
      .get();
  for (final t in tasks) {
    if (TaskSchedule.doneInPeriod(t.type, t.lastCompletedDate, today)) continue;
    await (db.update(db.tasks)..where((r) => r.id.equals(t.id)))
        .write(const TasksCompanion(isCompleted: Value(false)));
  }
}

/// Runs the rollover whenever the user or the day changes. Watch it once
/// near the root (the shell does).
final dailyRolloverProvider = Provider<void>((ref) {
  final today = ref.watch(todayProvider);
  final userId = ref.watch(currentUserIdProvider);
  final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
  if (!signedIn) return;
  unawaited(runDailyRollover(ref.read(databaseProvider), userId, today));
});
