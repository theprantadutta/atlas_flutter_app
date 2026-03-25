// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_tile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorldTile _$WorldTileFromJson(Map<String, dynamic> json) => WorldTile(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  imagePath: json['image_path'] as String?,
  tileType: $enumDecode(_$WorldTileTypeEnumMap, json['tile_type']),
  isUnlocked: json['is_unlocked'] as bool? ?? false,
  unlockRequirement: (json['unlock_requirement'] as num?)?.toInt() ?? 0,
  unlockCategory: json['unlock_category'] as String?,
  positionX: (json['position_x'] as num?)?.toInt() ?? 0,
  positionY: (json['position_y'] as num?)?.toInt() ?? 0,
  unlockedAt: json['unlocked_at'] == null
      ? null
      : DateTime.parse(json['unlocked_at'] as String),
  customProperties: json['custom_properties'] as Map<String, dynamic>?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$WorldTileToJson(WorldTile instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'description': instance.description,
  'image_path': instance.imagePath,
  'tile_type': _$WorldTileTypeEnumMap[instance.tileType]!,
  'is_unlocked': instance.isUnlocked,
  'unlock_requirement': instance.unlockRequirement,
  'unlock_category': instance.unlockCategory,
  'position_x': instance.positionX,
  'position_y': instance.positionY,
  'unlocked_at': instance.unlockedAt?.toIso8601String(),
  'custom_properties': instance.customProperties,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$WorldTileTypeEnumMap = {
  WorldTileType.grass: 'grass',
  WorldTileType.forest: 'forest',
  WorldTileType.mountain: 'mountain',
  WorldTileType.water: 'water',
  WorldTileType.desert: 'desert',
  WorldTileType.city: 'city',
  WorldTileType.building: 'building',
  WorldTileType.special: 'special',
};
