// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgressEntry _$ProgressEntryFromJson(Map<String, dynamic> json) =>
    ProgressEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      xpGained: (json['xp_gained'] as num?)?.toInt() ?? 0,
      tasksCompleted: (json['tasks_completed'] as num?)?.toInt() ?? 0,
      category: json['category'] as String?,
      categoryBreakdown: json['category_breakdown'] as Map<String, dynamic>?,
      taskTypeBreakdown: json['task_type_breakdown'] as Map<String, dynamic>?,
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      levelAtTime: (json['level_at_time'] as num?)?.toInt() ?? 1,
      additionalMetrics: json['additional_metrics'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ProgressEntryToJson(ProgressEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'date': instance.date.toIso8601String(),
      'xp_gained': instance.xpGained,
      'tasks_completed': instance.tasksCompleted,
      'category': instance.category,
      'category_breakdown': instance.categoryBreakdown,
      'task_type_breakdown': instance.taskTypeBreakdown,
      'streak_count': instance.streakCount,
      'level_at_time': instance.levelAtTime,
      'additional_metrics': instance.additionalMetrics,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
