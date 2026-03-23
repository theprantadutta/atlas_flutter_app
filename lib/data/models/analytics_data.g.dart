// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsData _$AnalyticsDataFromJson(
  Map<String, dynamic> json,
) => AnalyticsData(
  totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
  todayXp: (json['today_xp'] as num?)?.toInt() ?? 0,
  weekXp: (json['week_xp'] as num?)?.toInt() ?? 0,
  totalTasksCompleted: (json['total_tasks_completed'] as num?)?.toInt() ?? 0,
  todayTasks: (json['today_tasks'] as num?)?.toInt() ?? 0,
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
  currentLevel: (json['current_level'] as num?)?.toInt() ?? 1,
  avgXpPerDay: (json['avg_xp_per_day'] as num?)?.toDouble() ?? 0.0,
  categoryXpBreakdown: (json['category_xp_breakdown'] as Map<String, dynamic>?)
      ?.map((k, e) => MapEntry(k, (e as num).toInt())),
  xpTrend: json['xp_trend'] as List<dynamic>?,
  completionTrend: json['completion_trend'] as List<dynamic>?,
);

Map<String, dynamic> _$AnalyticsDataToJson(AnalyticsData instance) =>
    <String, dynamic>{
      'total_xp': instance.totalXp,
      'today_xp': instance.todayXp,
      'week_xp': instance.weekXp,
      'total_tasks_completed': instance.totalTasksCompleted,
      'today_tasks': instance.todayTasks,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'current_level': instance.currentLevel,
      'avg_xp_per_day': instance.avgXpPerDay,
      'category_xp_breakdown': instance.categoryXpBreakdown,
      'xp_trend': instance.xpTrend,
      'completion_trend': instance.completionTrend,
    };
