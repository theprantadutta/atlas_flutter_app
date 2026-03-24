// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  type: $enumDecode(_$TaskTypeEnumMap, json['type']),
  category: $enumDecode(_$TaskCategoryEnumMap, json['category']),
  xpReward: (json['xp_reward'] as num?)?.toInt() ?? 25,
  difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
  dueDate: json['due_date'] == null
      ? null
      : DateTime.parse(json['due_date'] as String),
  isCompleted: json['is_completed'] as bool? ?? false,
  streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
  lastCompletedDate: json['last_completed_date'] == null
      ? null
      : DateTime.parse(json['last_completed_date'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'title': instance.title,
  'description': instance.description,
  'type': _$TaskTypeEnumMap[instance.type]!,
  'category': _$TaskCategoryEnumMap[instance.category]!,
  'xp_reward': instance.xpReward,
  'difficulty': instance.difficulty,
  'due_date': instance.dueDate?.toIso8601String(),
  'is_completed': instance.isCompleted,
  'streak_count': instance.streakCount,
  'last_completed_date': instance.lastCompletedDate?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$TaskTypeEnumMap = {
  TaskType.daily: 'daily',
  TaskType.weekly: 'weekly',
  TaskType.longTerm: 'long_term',
};

const _$TaskCategoryEnumMap = {
  TaskCategory.health: 'health',
  TaskCategory.fitness: 'fitness',
  TaskCategory.mindfulness: 'mindfulness',
  TaskCategory.finance: 'finance',
  TaskCategory.work: 'work',
  TaskCategory.learning: 'learning',
  TaskCategory.social: 'social',
  TaskCategory.creative: 'creative',
  TaskCategory.custom: 'custom',
};
