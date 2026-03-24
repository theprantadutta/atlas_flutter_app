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
  final AchievementType achievementType;
  final Map<String, dynamic>? criteria;
  final bool isUnlocked;
  final double progress;
  final DateTime? unlockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Achievement({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.iconPath,
    required this.achievementType,
    this.criteria,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.unlockedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  /// Compute badge tier based on progress.
  String get badgeTier {
    if (progress >= 1.0) return 'legendary';
    if (progress >= 0.75) return 'epic';
    if (progress >= 0.5) return 'rare';
    if (progress >= 0.25) return 'common';
    return 'bronze';
  }

  Achievement copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? iconPath,
    AchievementType? achievementType,
    Map<String, dynamic>? criteria,
    bool? isUnlocked,
    double? progress,
    DateTime? unlockedAt,
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
      criteria: criteria ?? this.criteria,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
