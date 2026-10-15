import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/achievements/providers/achievement_providers.dart';

Achievement badge(String id, String title, String type, double target,
        {bool unlocked = false, double progress = 0}) =>
    Achievement(
      id: id,
      userId: 'u',
      title: title,
      achievementType: type,
      criteria: achievementCriteriaJson(target),
      isUnlocked: unlocked,
      progress: progress,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      isDirty: false,
      isDeleted: false,
    );

LedgerDay day(DateTime d, Map<String, int> items, {Map<String, int> cats = const {}}) => LedgerDay(
      date: d,
      xp: items.values.fold(0, (a, b) => a + b),
      count: items.length,
      items: items,
      categories: cats,
      types: const {},
    );

AchievementInputs inputs({
  List<LedgerDay> days = const [],
  int level = 1,
  int longestStreak = 0,
  int tiles = 0,
  Map<String, String> habits = const {},
}) =>
    AchievementInputs(
      days: days,
      level: level,
      longestStreak: longestStreak,
      unlockedTiles: tiles,
      habitTitles: habits,
    );

void main() {
  test('first completion unlocks First Light', () {
    final rows = [badge('a', 'First Light', 'milestone', 1)];
    expect(evaluateAchievements(rows, inputs()), isEmpty);
    final u = evaluateAchievements(rows, inputs(days: [day(DateTime(2025, 1, 1), {'h:x': 10})])).single;
    expect(u.unlock, isTrue);
    expect(u.progress, 1.0);
  });

  test('Tended Ten counts tasks only, as a fraction', () {
    final rows = [badge('a', 'Tended Ten', 'total', 10)];
    final days = [
      day(DateTime(2025, 1, 1), {'t:1': 25, 't:2': 25, 'h:x': 10}),
      day(DateTime(2025, 1, 2), {'t:3': 25}),
    ];
    final u = evaluateAchievements(rows, inputs(days: days)).single;
    expect(u.progress, closeTo(.3, 1e-9));
    expect(u.unlock, isFalse);
  });

  test('Week of Calm needs 7 consecutive mindfulness days', () {
    final rows = [badge('a', 'Week of Calm', 'streak', 7)];
    final days = [
      for (var i = 0; i < 7; i++)
        day(DateTime(2025, 1, 1 + i), {'h:m': 10}, cats: {'mindfulness': 10}),
    ];
    expect(evaluateAchievements(rows, inputs(days: days)).single.unlock, isTrue);
    final gap = [...days]..removeAt(3);
    expect(evaluateAchievements(rows, inputs(days: gap)).single.unlock, isFalse);
  });

  test('Hydrated and Bookworm read habit titles from the ledger', () {
    final habits = {'w': 'Drink enough water', 'r': 'Read 20 pages'};
    final days = [
      for (var i = 0; i < 5; i++) day(DateTime(2025, 1, 1 + i), {'h:w': 10, 'h:r': 10}),
    ];
    final rows = [badge('a', 'Hydrated', 'total', 100), badge('b', 'Bookworm', 'total', 1000)];
    final u = evaluateAchievements(rows, inputs(days: days, habits: habits));
    expect(u.firstWhere((e) => e.id == 'a').progress, closeTo(.05, 1e-9));
    expect(u.firstWhere((e) => e.id == 'b').progress, closeTo(.1, 1e-9)); // 5 × 20 pages
  });

  test('level, world and streak badges', () {
    final rows = [
      badge('l', 'Dawn to Dusk', 'level', 10),
      badge('w', 'World Builder', 'milestone', 30),
      badge('e', 'Evergreen', 'streak', 100),
    ];
    final u = evaluateAchievements(rows, inputs(level: 10, tiles: 15, longestStreak: 25));
    expect(u.firstWhere((e) => e.id == 'l').unlock, isTrue);
    expect(u.firstWhere((e) => e.id == 'w').progress, .5);
    expect(u.firstWhere((e) => e.id == 'e').progress, .25);
  });

  test('progress only moves forward and unlocked badges never relock', () {
    final rows = [
      badge('a', 'Tended Ten', 'total', 10, progress: .5),
      badge('b', 'First Light', 'milestone', 1, unlocked: true, progress: 1),
    ];
    // Fewer completions than before (an undo): nothing is written.
    expect(evaluateAchievements(rows, inputs(days: [day(DateTime(2025, 1, 1), {'t:1': 25})])), isEmpty);
  });

  test('unknown titles fall back to their type; special is left alone', () {
    final rows = [
      badge('s', 'Some streak', 'streak', 10),
      badge('x', 'Mystery', 'special', 1),
    ];
    final u = evaluateAchievements(rows, inputs(longestStreak: 5));
    expect(u.single.id, 's');
    expect(u.single.progress, .5);
  });
}
