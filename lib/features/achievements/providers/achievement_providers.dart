import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/achievement_dao.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;

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
    // title, desc, type, target, iconKey, unlocked, progress
    final seeds = <List<dynamic>>[
      ['First Light', 'Complete your first ritual', 'milestone', 1.0,
          'wb_twilight', true, 1.0],
      ['Tended Ten', 'Finish 10 tasks', 'total', 10.0, 'task_alt', true, 1.0],
      ['Week of Calm', 'A 7-day meditation streak', 'streak', 7.0,
          'self_improvement', true, 1.0],
      ['Hydrated', 'Drink water 100 times', 'total', 100.0, 'water_drop',
          true, 1.0],
      ['Dawn to Dusk', 'Reach level 10', 'level', 10.0, 'auto_awesome', true,
          1.0],
      ['World Builder', 'Unlock 30 tiles', 'milestone', 30.0, 'public', false,
          0.5],
      ['Evergreen', 'Keep a 100-day streak', 'streak', 100.0, 'forest', false,
          0.4],
      ['Bookworm', 'Read 1000 pages', 'total', 1000.0, 'menu_book', false,
          0.6],
    ];
    for (final s in seeds) {
      final unlocked = s[5] as bool;
      await _dao.insertAchievement(AchievementsCompanion(
        id: Value(_uuid.v4()),
        userId: Value(userId),
        title: Value(s[0] as String),
        description: Value(s[1] as String),
        iconPath: Value(s[4] as String),
        achievementType: Value(s[2] as String),
        criteria: Value(achievementCriteriaJson(s[3] as double)),
        isUnlocked: Value(unlocked),
        progress: Value(unlocked ? 1.0 : s[6] as double),
        unlockedAt: unlocked ? Value(now) : const Value(null),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ));
    }
  }
}
