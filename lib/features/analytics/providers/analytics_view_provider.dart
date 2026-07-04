import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/home/providers/home_provider.dart'
    show categoryVisual;
import 'package:atlas_flutter_app/features/progress/providers/progress_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';

/// A single category's share of earned XP, for the breakdown card.
class CategorySlice {
  const CategorySlice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

/// The insights view-model, computed entirely from the local Drift stores.
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

  static const empty = AnalyticsData(
    weeklyXp: [0, 0, 0, 0, 0, 0, 0],
    weekdayLabels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    categories: [],
    completionRate: 0,
    bestDay: '—',
    totalXpWeek: 0,
  );
}

const _dayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Insights derived from Drift: XP per day over the last week (from progress
/// entries) and a completion + category breakdown (from tasks).
final analyticsProvider = Provider.autoDispose<AnalyticsData>((ref) {
  final progress =
      ref.watch(progressEntriesStreamProvider).value ??
          const <ProgressEntry>[];
  final tasks = ref.watch(tasksStreamProvider).value ?? const <Task>[];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Last 7 days, oldest → newest, so the bars read left to right.
  final weeklyXp = <double>[];
  final labels = <String>[];
  var bestXp = -1;
  var bestName = '—';
  for (var i = 6; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    final xp = progress
        .where((p) => _sameDay(p.date, day))
        .fold<int>(0, (s, p) => s + p.xpGained);
    weeklyXp.add(xp.toDouble());
    labels.add(_dayInitials[day.weekday - 1]);
    if (xp > bestXp) {
      bestXp = xp;
      bestName = _dayNames[day.weekday - 1];
    }
  }
  final totalXpWeek = weeklyXp.fold<double>(0, (s, v) => s + v).round();
  if (bestXp <= 0) bestName = '—';

  // Completion + category mix from real tasks.
  final completed = tasks.where((t) => t.isCompleted).toList();
  final completionRate = tasks.isEmpty ? 0.0 : completed.length / tasks.length;

  final byCategory = <String, double>{};
  for (final t in completed) {
    final add = t.xpReward.toDouble();
    byCategory.update(t.category, (v) => v + add, ifAbsent: () => add);
  }
  final categories = byCategory.entries
      .map((e) => CategorySlice(
            _titleCase(e.key),
            e.value,
            categoryVisual(e.key).color,
          ))
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return AnalyticsData(
    weeklyXp: weeklyXp,
    weekdayLabels: labels,
    categories: categories.take(5).toList(),
    completionRate: completionRate.clamp(0.0, 1.0),
    bestDay: bestName,
    totalXpWeek: totalXpWeek,
  );
});

String _titleCase(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
