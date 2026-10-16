import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/achievements/providers/achievement_providers.dart';

/// Extra sample rows for the Progress / Achievements / Notifications goldens.

Notification notification(
  String id,
  String title,
  String body,
  String type,
  DateTime created, {
  bool read = false,
  String? entityType,
  String? data,
}) =>
    Notification(
      id: id,
      userId: 'u',
      title: title,
      body: body,
      type: type,
      data: data,
      isRead: read,
      entityType: entityType,
      createdAt: created,
      updatedAt: created,
      isDirty: false,
      isDeleted: false,
    );

List<Notification> sampleNotifications(DateTime now) => [
      notification('n1', 'Achievement unlocked', 'You earned "Week of Calm" for a 7-day streak.',
          'achievementUnlocked', now.subtract(const Duration(hours: 2))),
      notification('n2', 'You discovered Pine Ridge', 'A new place opened on your Atlas.',
          'systemMessage', now.subtract(const Duration(hours: 5)), entityType: 'world_tile'),
      notification('n3', 'Gentle reminder', 'Wind down before bed is waiting whenever you are.',
          'habitReminder', now.subtract(const Duration(hours: 28)), read: true),
      notification('n4', 'Streak milestone', 'You reached a 12-day streak. Keep tending.',
          'streakAlert', now.subtract(const Duration(days: 3)), read: true),
      notification('n5', 'Your weekly letter is ready', 'Aurora wrote to you about your week.',
          'dailySummary', now.subtract(const Duration(days: 9)), read: true, entityType: 'reflection'),
    ];

Achievement achievement(String id, String title, String desc, String type, double target, String icon,
        {bool unlocked = false, double progress = 0, DateTime? unlockedAt}) =>
    Achievement(
      id: id,
      userId: 'u',
      title: title,
      description: desc,
      iconPath: icon,
      achievementType: type,
      criteria: achievementCriteriaJson(target),
      isUnlocked: unlocked,
      progress: unlocked ? 1 : progress,
      unlockedAt: unlockedAt,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      isDirty: false,
      isDeleted: false,
    );

List<Achievement> sampleAchievements() => [
      achievement('a1', 'First Light', 'Complete your first ritual', 'milestone', 1, 'wb_twilight',
          unlocked: true, unlockedAt: DateTime(2025, 9, 2)),
      achievement('a2', 'Tended Ten', 'Finish 10 tasks', 'total', 10, 'task_alt',
          unlocked: true, unlockedAt: DateTime(2025, 9, 20)),
      achievement('a3', 'Week of Calm', 'A 7-day meditation streak', 'streak', 7, 'self_improvement',
          unlocked: true, unlockedAt: DateTime(2025, 10, 9)),
      achievement('a4', 'Hydrated', 'Drink water 100 times', 'total', 100, 'water_drop', progress: .62),
      achievement('a5', 'Dawn to Dusk', 'Reach level 10', 'level', 10, 'auto_awesome', progress: .3),
      achievement('a6', 'World Builder', 'Unlock 30 tiles', 'milestone', 30, 'public', progress: .4),
      achievement('a7', 'Evergreen', 'Keep a 100-day streak', 'streak', 100, 'forest', progress: .12),
      achievement('a8', 'Bookworm', 'Read 1000 pages', 'total', 1000, 'menu_book', progress: .08),
    ];
