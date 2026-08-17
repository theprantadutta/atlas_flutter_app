import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// Dummy data for Analytics, Progress, Notifications, Profile and Avatar.
/// TODO(backend): replace with real data.

// ─── Analytics ──────────────────────────────────────────────────────

class CategorySlice {
  const CategorySlice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

class AnalyticsData {
  const AnalyticsData({
    required this.weeklyXp,
    required this.weekdayLabels,
    required this.categories,
    required this.completionRate,
    required this.bestDay,
    required this.totalXpWeek,
  });

  final List<double> weeklyXp;
  final List<String> weekdayLabels;
  final List<CategorySlice> categories;
  final double completionRate; // 0..1
  final String bestDay;
  final int totalXpWeek;
}

final analyticsProvider = Provider<AnalyticsData>((ref) => const AnalyticsData(
      weeklyXp: [120, 85, 160, 95, 200, 140, 175],
      weekdayLabels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      categories: [
        CategorySlice('Mindfulness', 34, AppColors.categoryMindfulness),
        CategorySlice('Fitness', 26, AppColors.categoryFitness),
        CategorySlice('Learning', 22, AppColors.categoryLearning),
        CategorySlice('Health', 18, AppColors.categoryHealth),
      ],
      completionRate: 0.78,
      bestDay: 'Friday',
      totalXpWeek: 975,
    ));

// ─── Progress (daily breakdown) ─────────────────────────────────────

class DayEntry {
  const DayEntry({
    required this.label,
    required this.date,
    required this.xp,
    required this.tasks,
    required this.streak,
  });

  final String label;
  final String date;
  final int xp;
  final int tasks;
  final int streak;
}

final progressProvider = Provider<List<DayEntry>>((ref) => const [
      DayEntry(label: 'Today', date: 'Jun 28', xp: 175, tasks: 4, streak: 12),
      DayEntry(label: 'Yesterday', date: 'Jun 27', xp: 140, tasks: 3, streak: 11),
      DayEntry(label: 'Thursday', date: 'Jun 26', xp: 200, tasks: 5, streak: 10),
      DayEntry(label: 'Wednesday', date: 'Jun 25', xp: 95, tasks: 2, streak: 9),
      DayEntry(label: 'Tuesday', date: 'Jun 24', xp: 160, tasks: 4, streak: 8),
      DayEntry(label: 'Monday', date: 'Jun 23', xp: 85, tasks: 2, streak: 7),
      DayEntry(label: 'Sunday', date: 'Jun 22', xp: 120, tasks: 3, streak: 6),
    ]);

// ─── Notifications ──────────────────────────────────────────────────

class SampleNotification {
  const SampleNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
    required this.color,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;
  final Color color;
  final bool read;

  SampleNotification copyWith({bool? read}) => SampleNotification(
        id: id,
        title: title,
        body: body,
        timeLabel: timeLabel,
        icon: icon,
        color: color,
        read: read ?? this.read,
      );
}

class NotificationsNotifier extends Notifier<List<SampleNotification>> {
  @override
  List<SampleNotification> build() => const [
        SampleNotification(
            id: 'n1',
            title: 'Achievement unlocked',
            body: 'You earned "Week of Calm" for a 7-day streak.',
            timeLabel: '2h ago',
            icon: Icons.emoji_events_rounded,
            color: AppColors.badgeRare),
        SampleNotification(
            id: 'n2',
            title: 'Your world grew',
            body: 'A new Forest tile bloomed overnight.',
            timeLabel: '5h ago',
            icon: Icons.park_rounded,
            color: AppColors.secondary),
        SampleNotification(
            id: 'n3',
            title: 'Gentle reminder',
            body: 'Meditation is waiting whenever you are.',
            timeLabel: 'Yesterday',
            icon: Icons.self_improvement_rounded,
            color: AppColors.categoryMindfulness,
            read: true),
        SampleNotification(
            id: 'n4',
            title: 'Streak milestone',
            body: 'You reached a 12-day streak. Keep tending.',
            timeLabel: '2d ago',
            icon: Icons.local_fire_department_rounded,
            color: AppColors.streakFlame,
            read: true),
      ];

  void markAllRead() => state = [for (final n in state) n.copyWith(read: true)];

  void dismiss(String id) => state = [
        for (final n in state)
          if (n.id != id) n,
      ];

  int get unread => state.where((n) => !n.read).length;
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<SampleNotification>>(
        NotificationsNotifier.new);

// ─── Profile / Avatar ───────────────────────────────────────────────

class AttributeStat {
  const AttributeStat(this.label, this.value, this.icon, this.color);
  final String label;
  final int value; // 0..100
  final IconData icon;
  final Color color;
}

final attributesProvider = Provider<List<AttributeStat>>((ref) => const [
      AttributeStat('Strength', 64, Icons.fitness_center_rounded,
          AppColors.categoryFitness),
      AttributeStat(
          'Wisdom', 78, Icons.auto_stories_rounded, AppColors.categoryLearning),
      AttributeStat('Intelligence', 71, Icons.psychology_rounded,
          AppColors.categoryMindfulness),
    ]);

/// Selectable swatch palettes for avatar customization.
class AvatarOptions {
  AvatarOptions._();

  static const skin = [
    Color(0xFFF6D5B8),
    Color(0xFFE8B98E),
    Color(0xFFC68A5E),
    Color(0xFF8D5A3C),
    Color(0xFF5C3A29),
  ];

  static const hair = [
    Color(0xFF2B2B2B),
    Color(0xFF6B4423),
    Color(0xFFC58B3B),
    Color(0xFF8B9CF7),
    Color(0xFF5EEAD4),
  ];

  static const outfit = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.tertiary,
    AppColors.categorySocial,
    AppColors.categoryFinance,
  ];
}
