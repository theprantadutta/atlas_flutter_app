// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Avatar _$AvatarFromJson(Map<String, dynamic> json) => Avatar(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  level: (json['level'] as num?)?.toInt() ?? 1,
  currentXp: (json['current_xp'] as num?)?.toInt() ?? 0,
  strength: (json['strength'] as num?)?.toInt() ?? 0,
  wisdom: (json['wisdom'] as num?)?.toInt() ?? 0,
  intelligence: (json['intelligence'] as num?)?.toInt() ?? 0,
  appearance: json['appearance'] as Map<String, dynamic>?,
  unlockedItems: (json['unlocked_items'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AvatarToJson(Avatar instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'level': instance.level,
  'current_xp': instance.currentXp,
  'strength': instance.strength,
  'wisdom': instance.wisdom,
  'intelligence': instance.intelligence,
  'appearance': instance.appearance,
  'unlocked_items': instance.unlockedItems,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
