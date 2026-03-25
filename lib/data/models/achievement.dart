import 'package:json_annotation/json_annotation.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';

part 'achievement.g.dart';

@JsonSerializable()
class Achievement {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? iconPath;
  @JsonKey(name: 'type')
  final AchievementType achievementType;
  final double targetValue;
  final String? category;
  final bool isUnlocked;
  final double progress;
  final DateTime? unlockedAt;
  final String badgeTier;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Achievement({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.iconPath,
    required this.achievementType,
    this.targetValue = 0.0,
    this.category,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.unlockedAt,
    this.badgeTier = 'bronze',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  Achievement copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? iconPath,
    AchievementType? achievementType,
    double? targetValue,
    String? category,
    bool? isUnlocked,
    double? progress,
    DateTime? unlockedAt,
    String? badgeTier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      achievementType: achievementType ?? this.achievementType,
      targetValue: targetValue ?? this.targetValue,
      category: category ?? this.category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      badgeTier: badgeTier ?? this.badgeTier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
