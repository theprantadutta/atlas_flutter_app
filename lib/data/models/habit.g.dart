// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Habit _$HabitFromJson(Map<String, dynamic> json) => Habit(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  category: $enumDecode(_$HabitCategoryEnumMap, json['category']),
  frequency: $enumDecode(_$HabitFrequencyEnumMap, json['frequency']),
  difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
  isCompletedToday: json['is_completed_today'] as bool? ?? false,
  streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
  completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
  totalCompletions: (json['total_completions'] as num?)?.toInt() ?? 0,
  reminderTime: json['reminder_time'] as String?,
  lastCompletedDate: json['last_completed_date'] == null
      ? null
      : DateTime.parse(json['last_completed_date'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$HabitToJson(Habit instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'title': instance.title,
  'description': instance.description,
  'category': _$HabitCategoryEnumMap[instance.category]!,
  'frequency': _$HabitFrequencyEnumMap[instance.frequency]!,
  'difficulty': instance.difficulty,
  'is_completed_today': instance.isCompletedToday,
  'streak_count': instance.streakCount,
  'longest_streak': instance.longestStreak,
  'completion_rate': instance.completionRate,
  'total_completions': instance.totalCompletions,
  'reminder_time': instance.reminderTime,
  'last_completed_date': instance.lastCompletedDate?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$HabitCategoryEnumMap = {
  HabitCategory.health: 'health',
  HabitCategory.fitness: 'fitness',
  HabitCategory.learning: 'learning',
  HabitCategory.mindfulness: 'mindfulness',
  HabitCategory.productivity: 'productivity',
  HabitCategory.social: 'social',
  HabitCategory.creativity: 'creativity',
  HabitCategory.personal: 'personal',
};

const _$HabitFrequencyEnumMap = {
  HabitFrequency.daily: 'daily',
  HabitFrequency.weekly: 'weekly',
  HabitFrequency.custom: 'custom',
};
