// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  iconPath: json['icon_path'] as String?,
  achievementType: $enumDecode(
    _$AchievementTypeEnumMap,
    json['achievement_type'],
  ),
  criteria: json['criteria'] as Map<String, dynamic>?,
  isUnlocked: json['is_unlocked'] as bool? ?? false,
  progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
  unlockedAt: json['unlocked_at'] == null
      ? null
      : DateTime.parse(json['unlocked_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'icon_path': instance.iconPath,
      'achievement_type': _$AchievementTypeEnumMap[instance.achievementType]!,
      'criteria': instance.criteria,
      'is_unlocked': instance.isUnlocked,
      'progress': instance.progress,
      'unlocked_at': instance.unlockedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$AchievementTypeEnumMap = {
  AchievementType.streak: 'streak',
  AchievementType.total: 'total',
  AchievementType.milestone: 'milestone',
  AchievementType.category: 'category',
  AchievementType.level: 'level',
  AchievementType.special: 'special',
};
