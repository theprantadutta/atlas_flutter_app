import 'package:json_annotation/json_annotation.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/core/utils/extensions.dart';
import 'package:atlas_flutter_app/data/models/enums.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskType type;
  final TaskCategory category;
  final int xpReward;
  final int difficulty;
  final DateTime? dueDate;
  final bool isCompleted;
  final int streakCount;
  final DateTime? lastCompletedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.type,
    required this.category,
    this.xpReward = 25,
    this.difficulty = 1,
    this.dueDate,
    this.isCompleted = false,
    this.streakCount = 0,
    this.lastCompletedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  /// Calculate XP reward based on type, difficulty, and streak.
  int get calculatedXpReward {
    return GamificationConstants.calculateTaskXp(
      taskType: type.name,
      difficulty: difficulty,
      streakCount: streakCount,
    );
  }

  /// Whether this task is overdue.
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isOverdue;
  }

  /// Whether this task is due today.
  bool get isDueToday {
    if (dueDate == null) return false;
    return dueDate!.isToday;
  }

  /// Get the primary attribute this task contributes to.
  String get primaryAttribute {
    switch (category) {
      case TaskCategory.fitness:
      case TaskCategory.health:
        return 'Strength';
      case TaskCategory.learning:
      case TaskCategory.mindfulness:
        return 'Wisdom';
      case TaskCategory.work:
      case TaskCategory.creative:
        return 'Intelligence';
      case TaskCategory.finance:
      case TaskCategory.custom:
      case TaskCategory.social:
        return 'Wisdom';
    }
  }

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskType? type,
    TaskCategory? category,
    int? xpReward,
    int? difficulty,
    DateTime? dueDate,
    bool? isCompleted,
    int? streakCount,
    DateTime? lastCompletedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
      difficulty: difficulty ?? this.difficulty,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      streakCount: streakCount ?? this.streakCount,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
