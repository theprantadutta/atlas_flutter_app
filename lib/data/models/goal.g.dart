// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Goal _$GoalFromJson(Map<String, dynamic> json) => Goal(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  category: $enumDecode(_$GoalCategoryEnumMap, json['category']),
  priority:
      $enumDecodeNullable(_$GoalPriorityEnumMap, json['priority']) ??
      GoalPriority.medium,
  status:
      $enumDecodeNullable(_$GoalStatusEnumMap, json['status']) ??
      GoalStatus.notStarted,
  progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
  startDate: json['start_date'] == null
      ? null
      : DateTime.parse(json['start_date'] as String),
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  parentGoalId: json['parent_goal_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$GoalToJson(Goal instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'title': instance.title,
  'description': instance.description,
  'category': _$GoalCategoryEnumMap[instance.category]!,
  'priority': _$GoalPriorityEnumMap[instance.priority]!,
  'status': _$GoalStatusEnumMap[instance.status]!,
  'progress': instance.progress,
  'start_date': instance.startDate?.toIso8601String(),
  'deadline': instance.deadline?.toIso8601String(),
  'completed_at': instance.completedAt?.toIso8601String(),
  'parent_goal_id': instance.parentGoalId,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$GoalCategoryEnumMap = {
  GoalCategory.career: 'career',
  GoalCategory.health: 'health',
  GoalCategory.education: 'education',
  GoalCategory.financial: 'financial',
  GoalCategory.personal: 'personal',
  GoalCategory.fitness: 'fitness',
  GoalCategory.social: 'social',
  GoalCategory.creativity: 'creativity',
};

const _$GoalPriorityEnumMap = {
  GoalPriority.low: 'low',
  GoalPriority.medium: 'medium',
  GoalPriority.high: 'high',
  GoalPriority.critical: 'critical',
};

const _$GoalStatusEnumMap = {
  GoalStatus.notStarted: 'not_started',
  GoalStatus.inProgress: 'in_progress',
  GoalStatus.completed: 'completed',
  GoalStatus.onHold: 'on_hold',
  GoalStatus.cancelled: 'cancelled',
};
