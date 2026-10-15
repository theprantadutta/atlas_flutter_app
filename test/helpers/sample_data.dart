import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';

/// Deterministic sample data matching the Daylight mocks. "Today" is a
/// Tuesday so the week strip reads M 13 … S 19 like the design.
final kToday = DateTime(2025, 10, 14);
final _created = DateTime(2025, 9, 1);

Habit habit(
  String id,
  String title,
  String category, {
  bool done = false,
  int streak = 0,
  String? time,
  String frequency = 'daily',
}) =>
    Habit(
      id: id,
      userId: 'u',
      title: title,
      category: category,
      frequency: frequency,
      difficulty: 1,
      isCompletedToday: done,
      streakCount: streak,
      longestStreak: streak,
      completionRate: 0,
      totalCompletions: streak,
      reminderTime: time,
      lastCompletedDate: done ? kToday : addDays(kToday, -1),
      createdAt: _created,
      updatedAt: _created,
      isDirty: false,
      isDeleted: false,
    );

Task task(
  String id,
  String title,
  String category, {
  String type = 'daily',
  int xp = 25,
  DateTime? due,
  bool done = false,
}) =>
    Task(
      id: id,
      userId: 'u',
      title: title,
      type: type,
      category: category,
      xpReward: xp,
      difficulty: 2,
      dueDate: due,
      isCompleted: done,
      streakCount: 0,
      lastCompletedDate: done ? kToday : null,
      createdAt: _created,
      updatedAt: _created,
      isDirty: false,
      isDeleted: false,
    );

Goal goal(String id, String title, String category, double progress, {int? inDays}) => Goal(
      id: id,
      userId: 'u',
      title: title,
      category: category,
      priority: 'medium',
      status: progress >= 1 ? 'completed' : 'inProgress',
      progress: progress,
      deadline: inDays == null ? null : addDays(kToday, inDays),
      completedAt: progress >= 1 ? addDays(kToday, -3) : null,
      createdAt: _created,
      updatedAt: _created,
      isDirty: false,
      isDeleted: false,
    );

final sampleHabits = [
  habit('h1', 'Move your body', 'fitness', done: true, streak: 12),
  habit('h2', 'Drink enough water', 'health', done: true, streak: 6),
  habit('h3', 'Stretch for 10 minutes', 'fitness', done: true, streak: 5),
  habit('h4', 'Wind down before bed', 'mindfulness', time: '22:30', streak: 2),
  habit('h5', 'Rest properly tonight', 'health', time: '23:30'),
];

final sampleTasks = [
  task('t1', 'Reply to Sam', 'work', due: DateTime(2025, 10, 14, 11), done: true),
  task('t2', 'Read 20 pages', 'learning', xp: 20, due: DateTime(2025, 10, 14, 21)),
  task('t3', 'Plan the week', 'mindfulness', type: 'weekly', xp: 45, due: DateTime(2025, 10, 19)),
  task('t4', 'Book the dentist', 'health', type: 'longTerm', xp: 30),
];

final sampleGoals = [
  goal('g1', 'Run a half marathon', 'fitness', .62, inDays: 42),
  goal('g2', 'Read 24 books this year', 'learning', .46, inDays: 180),
  goal('g3', 'Learn watercolor basics', 'creative', 1),
];

/// Seven days of history per habit, oldest first (the mock's sparklines).
const _patterns = {
  'h1': [1, 1, 1, 1, 1, 1, 1],
  'h2': [1, 1, 1, 0, 1, 1, 1],
  'h3': [0, 1, 1, 1, 1, 1, 1],
  'h4': [1, 1, 0, 1, 1, 1, 0],
  'h5': [0, 0, 1, 0, 0, 1, 0],
};

/// A ledger with the habit history above and a week of XP that matches the
/// Insights mock (975 XP, Friday the best day).
List<LedgerDay> sampleLedger() {
  const weekXp = [120, 85, 160, 95, 200, 140, 175]; // Mon..Sun
  final out = <LedgerDay>[];
  for (var i = 0; i < 21; i++) {
    final d = addDays(kToday, -i);
    final items = <String, int>{};
    if (i < 7) {
      _patterns.forEach((id, p) {
        if (p[6 - i] == 1) items[Ledger.habitKey(id)] = 10;
      });
    }
    final weekIndex = d.weekday - 1;
    final xp = i < 7 ? weekXp[weekIndex] : 60 + (i * 13) % 90;
    out.add(LedgerDay(
      date: d,
      xp: xp,
      count: items.length + 1,
      items: items,
      categories: {
        'health': (xp * .47).round(),
        'mindfulness': (xp * .31).round(),
        'learning': xp - (xp * .47).round() - (xp * .31).round(),
      },
      types: {'habit': items.length},
    ));
  }
  return out;
}

const _tileTypes = ['grass', 'forest', 'mountain', 'water', 'desert', 'city', 'building', 'special'];
const _tileNames = {
  'grass': 'Meadow', 'forest': 'Forest', 'mountain': 'Mountain', 'water': 'Lake',
  'desert': 'Dunes', 'city': 'Town', 'building': 'Cottage', 'special': 'Wonder',
};

/// The seeded 5×6 world with the first [unlocked] places discovered.
List<WorldTile> sampleTiles({int unlocked = 12}) => [
      for (var i = 0; i < 30; i++)
        WorldTile(
          id: 'w$i',
          userId: 'u',
          name: _tileNames[_tileTypes[i % 8]]!,
          tileType: _tileTypes[i % 8],
          isUnlocked: i < unlocked,
          unlockRequirement: i == 0 ? 0 : 50 + (i - 1) * 25,
          positionX: i % 5,
          positionY: i ~/ 5,
          unlockedAt: i < unlocked ? addDays(kToday, -(unlocked - i) * 3) : null,
          createdAt: _created,
          updatedAt: _created,
          isDirty: false,
          isDeleted: false,
        ),
    ];
