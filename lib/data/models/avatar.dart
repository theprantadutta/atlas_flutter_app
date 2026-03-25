import 'package:json_annotation/json_annotation.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';

part 'avatar.g.dart';

@JsonSerializable()
class Avatar {
  final String id;
  final String userId;
  final String name;
  final int level;
  final int currentXp;
  final int strength;
  final int wisdom;
  final int intelligence;
  final Map<String, dynamic>? appearance;
  final List<String>? unlockedItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Avatar({
    required this.id,
    required this.userId,
    required this.name,
    this.level = 1,
    this.currentXp = 0,
    this.strength = 0,
    this.wisdom = 0,
    this.intelligence = 0,
    this.appearance,
    this.unlockedItems,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Avatar.fromJson(Map<String, dynamic> json) =>
      _$AvatarFromJson(json);

  Map<String, dynamic> toJson() => _$AvatarToJson(this);

  /// Progress to the next level as a percentage (0.0 - 1.0).
  double get progressToNextLevel {
    final currentLevelXp = GamificationConstants.xpRequiredForLevel(level);
    final nextLevelXp = GamificationConstants.xpRequiredForLevel(level + 1);
    final xpRange = nextLevelXp - currentLevelXp;
    if (xpRange <= 0) return 1.0;
    final xpIntoCurrentLevel = currentXp - currentLevelXp;
    return (xpIntoCurrentLevel / xpRange).clamp(0.0, 1.0);
  }

  /// XP required to reach a specific level.
  int xpRequiredForLevel(int level) {
    return GamificationConstants.xpRequiredForLevel(level);
  }

  Avatar copyWith({
    String? id,
    String? userId,
    String? name,
    int? level,
    int? currentXp,
    int? strength,
    int? wisdom,
    int? intelligence,
    Map<String, dynamic>? appearance,
    List<String>? unlockedItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Avatar(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      strength: strength ?? this.strength,
      wisdom: wisdom ?? this.wisdom,
      intelligence: intelligence ?? this.intelligence,
      appearance: appearance ?? this.appearance,
      unlockedItems: unlockedItems ?? this.unlockedItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
