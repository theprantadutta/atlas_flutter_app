import 'package:json_annotation/json_annotation.dart';

part 'analytics_data.g.dart';

@JsonSerializable()
class AnalyticsData {
  final int totalXp;
  final int todayXp;
  final int weekXp;
  final int totalTasksCompleted;
  final int todayTasks;
  final int currentStreak;
  final int longestStreak;
  final int currentLevel;
  final double avgXpPerDay;
  final Map<String, int>? categoryXpBreakdown;
  final List<dynamic>? xpTrend;
  final List<dynamic>? completionTrend;

  const AnalyticsData({
    this.totalXp = 0,
    this.todayXp = 0,
    this.weekXp = 0,
    this.totalTasksCompleted = 0,
    this.todayTasks = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.currentLevel = 1,
    this.avgXpPerDay = 0.0,
    this.categoryXpBreakdown,
    this.xpTrend,
    this.completionTrend,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsDataFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsDataToJson(this);

  AnalyticsData copyWith({
    int? totalXp,
    int? todayXp,
    int? weekXp,
    int? totalTasksCompleted,
    int? todayTasks,
    int? currentStreak,
    int? longestStreak,
    int? currentLevel,
    double? avgXpPerDay,
    Map<String, int>? categoryXpBreakdown,
    List<dynamic>? xpTrend,
    List<dynamic>? completionTrend,
  }) {
    return AnalyticsData(
      totalXp: totalXp ?? this.totalXp,
      todayXp: todayXp ?? this.todayXp,
      weekXp: weekXp ?? this.weekXp,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      todayTasks: todayTasks ?? this.todayTasks,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      currentLevel: currentLevel ?? this.currentLevel,
      avgXpPerDay: avgXpPerDay ?? this.avgXpPerDay,
      categoryXpBreakdown: categoryXpBreakdown ?? this.categoryXpBreakdown,
      xpTrend: xpTrend ?? this.xpTrend,
      completionTrend: completionTrend ?? this.completionTrend,
    );
  }
}
