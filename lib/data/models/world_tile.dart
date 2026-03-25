import 'package:json_annotation/json_annotation.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';

part 'world_tile.g.dart';

@JsonSerializable()
class WorldTile {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? imagePath;
  final WorldTileType tileType;
  final bool isUnlocked;
  final int unlockRequirement;
  final String? unlockCategory;
  final int positionX;
  final int positionY;
  final DateTime? unlockedAt;
  final Map<String, dynamic>? customProperties;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorldTile({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.imagePath,
    required this.tileType,
    this.isUnlocked = false,
    this.unlockRequirement = 0,
    this.unlockCategory,
    this.positionX = 0,
    this.positionY = 0,
    this.unlockedAt,
    this.customProperties,
    this.createdAt,
    this.updatedAt,
  });

  factory WorldTile.fromJson(Map<String, dynamic> json) =>
      _$WorldTileFromJson(json);

  Map<String, dynamic> toJson() => _$WorldTileToJson(this);

  WorldTile copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? imagePath,
    WorldTileType? tileType,
    bool? isUnlocked,
    int? unlockRequirement,
    String? unlockCategory,
    int? positionX,
    int? positionY,
    DateTime? unlockedAt,
    Map<String, dynamic>? customProperties,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorldTile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      tileType: tileType ?? this.tileType,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
      unlockCategory: unlockCategory ?? this.unlockCategory,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      customProperties: customProperties ?? this.customProperties,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
