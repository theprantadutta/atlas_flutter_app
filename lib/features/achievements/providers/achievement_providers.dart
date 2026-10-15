import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/achievement_dao.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;
import 'package:atlas_flutter_app/features/world/providers/world_providers.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

/// Reactive stream of the current user's achievements from Drift (source of
/// truth), oldest first so the gallery order is stable.
final achievementsStreamProvider =
    StreamProvider.autoDispose<List<Achievement>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final dao = ref.read(achievementDaoProvider);
  // Seed a starter gallery once so a fresh offline DB has badges to show.
  ref.read(achievementActionsProvider).ensureSeeded(userId);
  return dao.watchAchievements(userId);
});

final achievementActionsProvider = Provider<AchievementActions>((ref) {
  return AchievementActions(ref.read(achievementDaoProvider));
});

// ─── Criteria + tier helpers ──────────────────────────────────────────
// Drift stores the criteria as JSON ({target_value, ...}) to stay
// field-for-field with the backend's owned AchievementCriteria. The badge
// tier is derived from type + target (matching the backend formula) rather
// than stored, so it can't drift out of sync.

double achievementTargetFromCriteria(String? criteriaJson) {
  if (criteriaJson == null || criteriaJson.isEmpty) return 0;
  try {
    final m = jsonDecode(criteriaJson) as Map<String, dynamic>;
    return (m['target_value'] as num?)?.toDouble() ?? 0;
  } catch (_) {
    return 0;
  }
}

String achievementCriteriaJson(double target) =>
    jsonEncode({'target_value': target, 'category': null, 'task_type': null});

/// Mirror of the backend `Achievement.CalculateBadgeTier`. Returns one of
/// bronze | common | rare | epic | legendary.
String achievementBadgeTier(String type, double target) {
  return switch (type) {
    'streak' => switch (target) {
        < 7 => 'bronze',
        < 20 => 'common',
        < 50 => 'rare',
        < 100 => 'epic',
        _ => 'legendary',
      },
    'total' => switch (target) {
        < 50 => 'bronze',
        < 100 => 'common',
        < 500 => 'rare',
        < 1000 => 'epic',
        _ => 'legendary',
      },
    'milestone' || 'level' => switch (target) {
        < 5 => 'bronze',
        < 10 => 'common',
        < 25 => 'rare',
        < 50 => 'epic',
        _ => 'legendary',
      },
    'category' => 'rare',
    'special' => 'legendary',
    _ => 'bronze',
  };
}

/// Local-first achievement mutations. Unlocks normally come from progress
/// (server-awarded); offline we just seed the gallery.
class AchievementActions {
  AchievementActions(this._dao);
  final AchievementDao _dao;
  final _uuid = const Uuid();
  final _seeded = <String>{};

  Future<void> ensureSeeded(String userId) async {
    if (_seeded.contains(userId)) return;
    _seeded.add(userId);
    if (await _dao.countForUser(userId) > 0) return;

    final now = DateTime.now();
    // The achievement catalogue (what can be earned). A fresh account has
    // earned none yet, so every badge starts locked with zero progress.
    // title, desc, type, target, iconKey
    final seeds = <List<dynamic>>[
      ['First Light', 'Complete your first ritual', 'milestone', 1.0,
          'wb_twilight'],
      ['Tended Ten', 'Finish 10 tasks', 'total', 10.0, 'task_alt'],
      ['Week of Calm', 'A 7-day meditation streak', 'streak', 7.0,
          'self_improvement'],
      ['Hydrated', 'Drink water 100 times', 'total', 100.0, 'water_drop'],
      ['Dawn to Dusk', 'Reach level 10', 'level', 10.0, 'auto_awesome'],
      ['World Builder', 'Unlock 30 tiles', 'milestone', 30.0, 'public'],
      ['Evergreen', 'Keep a 100-day streak', 'streak', 100.0, 'forest'],
      ['Bookworm', 'Read 1000 pages', 'total', 1000.0, 'menu_book'],
    ];
    for (final s in seeds) {
      await _dao.insertAchievement(AchievementsCompanion(
        id: Value(_uuid.v4()),
        userId: Value(userId),
        title: Value(s[0] as String),
        description: Value(s[1] as String),
        iconPath: Value(s[4] as String),
        achievementType: Value(s[2] as String),
        criteria: Value(achievementCriteriaJson(s[3] as double)),
        isUnlocked: const Value(false),
        progress: const Value(0.0),
        unlockedAt: const Value(null),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ));
    }
  }
}

// ─── Evaluation (bug: achievements never progressed or unlocked) ──────

/// Everything the achievement rules look at, gathered from local data.
class AchievementInputs {
  const AchievementInputs({
    required this.days,
    required this.level,
    required this.longestStreak,
    required this.unlockedTiles,
    required this.habitTitles,
  });

  final List<LedgerDay> days;
  final int level;

  /// The best run of active days (current or past).
  final int longestStreak;
  final int unlockedTiles;

  /// habit id → title, to recognise water and reading habits in the ledger.
  final Map<String, String> habitTitles;

  int get totalCompletions => days.fold(0, (s, d) => s + d.items.length);
  int get taskCompletions =>
      days.fold(0, (s, d) => s + d.items.keys.where((k) => k.startsWith('t:')).length);

  /// Longest run of consecutive days with XP in [category].
  int longestCategoryRun(String category) {
    final dates = days
        .where((d) => (d.categories[category] ?? 0) > 0)
        .map((d) => DateTime.utc(d.date.year, d.date.month, d.date.day))
        .toSet()
        .toList()
      ..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in dates) {
      run = (prev != null && d.difference(prev).inDays == 1) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  /// Habit completions whose title matches [pattern].
  int habitCompletionsMatching(RegExp pattern) {
    var n = 0;
    for (final d in days) {
      for (final k in d.items.keys) {
        if (!k.startsWith('h:')) continue;
        final title = habitTitles[k.substring(2)];
        if (title != null && pattern.hasMatch(title.toLowerCase())) n++;
      }
    }
    return n;
  }

  /// Pages read: the number in a reading habit's title ("Read 20 pages"),
  /// or 10 pages a session when it doesn't say.
  int pagesRead() {
    final reading = RegExp(r'\b(read|book|pages?)\b');
    final count = RegExp(r'(\d+)\s*pages?');
    var pages = 0;
    for (final d in days) {
      for (final k in d.items.keys) {
        if (!k.startsWith('h:')) continue;
        final title = habitTitles[k.substring(2)]?.toLowerCase();
        if (title == null || !reading.hasMatch(title)) continue;
        final m = count.firstMatch(title);
        pages += m == null ? 10 : int.parse(m[1]!);
      }
    }
    return pages;
  }
}

/// The current value toward an achievement: by title for the seeded
/// catalogue, otherwise by type. Null when it can't be measured locally (the
/// server's value is left alone).
double? achievementValue(String title, String type, AchievementInputs x) {
  switch (title) {
    case 'First Light':
      return x.totalCompletions.toDouble();
    case 'Tended Ten':
      return x.taskCompletions.toDouble();
    case 'Week of Calm':
      return x.longestCategoryRun('mindfulness').toDouble();
    case 'Hydrated':
      return x.habitCompletionsMatching(RegExp(r'\b(water|hydrat)')).toDouble();
    case 'Dawn to Dusk':
      return x.level.toDouble();
    case 'World Builder':
      return x.unlockedTiles.toDouble();
    case 'Evergreen':
      return x.longestStreak.toDouble();
    case 'Bookworm':
      return x.pagesRead().toDouble();
  }
  return switch (type) {
    'streak' => x.longestStreak.toDouble(),
    'total' || 'milestone' => x.totalCompletions.toDouble(),
    'level' => x.level.toDouble(),
    _ => null,
  };
}

/// A pending change to one achievement row.
class AchievementUpdate {
  const AchievementUpdate(this.id, this.progress, this.unlock);
  final String id;
  final double progress;
  final bool unlock;

  @override
  String toString() => 'AchievementUpdate($id, $progress, unlock: $unlock)';
}

/// Pure: which rows need writing. Progress only moves forward, and an
/// unlocked badge never locks again (not even after an undo).
List<AchievementUpdate> evaluateAchievements(List<Achievement> rows, AchievementInputs x) {
  final out = <AchievementUpdate>[];
  for (final a in rows) {
    if (a.isUnlocked) continue;
    final target = achievementTargetFromCriteria(a.criteria);
    if (target <= 0) continue;
    final value = achievementValue(a.title, a.achievementType, x);
    if (value == null) continue;
    final progress = (value / target).clamp(0.0, 1.0);
    if (progress >= 1.0) {
      out.add(AchievementUpdate(a.id, 1.0, true));
    } else if (progress > a.progress + 0.0005) {
      out.add(AchievementUpdate(a.id, progress, false));
    }
  }
  return out;
}

/// Re-evaluates achievements whenever the ledger, level, habits or world
/// change, writing only rows whose progress or unlock state actually moved
/// (so its own writes settle instead of looping). Watch it once near the
/// root: `ref.watch(achievementEvaluatorProvider);`
final achievementEvaluatorProvider = Provider<void>((ref) {
  if (!ref.watch(authProvider.select((s) => s.isAuthenticated))) return;
  final rows = ref.watch(achievementsStreamProvider).value;
  if (rows == null || rows.isEmpty) return;
  final stats = ref.watch(playerStatsProvider);
  final days = ref.watch(ledgerDaysProvider);
  final habits = ref.watch(habitsStreamProvider).value ?? const <Habit>[];
  final tiles = ref.watch(worldTilesStreamProvider).value ?? const <WorldTile>[];
  final updates = evaluateAchievements(
    rows,
    AchievementInputs(
      days: days,
      level: stats.level.level,
      longestStreak: stats.bestStreak > stats.streak ? stats.bestStreak : stats.streak,
      unlockedTiles: tiles.where((t) => t.isUnlocked).length,
      habitTitles: {for (final h in habits) h.id: h.title},
    ),
  );
  if (updates.isEmpty) return;
  final db = ref.read(databaseProvider);
  unawaited(() async {
    final now = DateTime.now();
    for (final u in updates) {
      await (db.update(db.achievements)..where((a) => a.id.equals(u.id))).write(AchievementsCompanion(
        progress: Value(u.progress),
        isUnlocked: u.unlock ? const Value(true) : const Value.absent(),
        unlockedAt: u.unlock ? Value(now) : const Value.absent(),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ));
    }
  }());
});
