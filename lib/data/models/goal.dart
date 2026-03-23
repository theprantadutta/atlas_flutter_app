import 'package:json_annotation/json_annotation.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';

part 'goal.g.dart';

@JsonSerializable()
class Goal {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final GoalCategory category;
  final GoalPriority priority;
  final GoalStatus status;
  final double progress;
  final DateTime? startDate;
  final DateTime? deadline;
  final DateTime? completedAt;
  final String? parentGoalId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    this.priority = GoalPriority.medium,
    this.status = GoalStatus.notStarted,
    this.progress = 0.0,
    this.startDate,
    this.deadline,
    this.completedAt,
    this.parentGoalId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);

  Map<String, dynamic> toJson() => _$GoalToJson(this);

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    GoalCategory? category,
    GoalPriority? priority,
    GoalStatus? status,
    double? progress,
    DateTime? startDate,
    DateTime? deadline,
    DateTime? completedAt,
    String? parentGoalId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
      parentGoalId: parentGoalId ?? this.parentGoalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
