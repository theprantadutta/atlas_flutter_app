import 'package:json_annotation/json_annotation.dart';

part 'progress_entry.g.dart';

@JsonSerializable()
class ProgressEntry {
  final String id;
  final String userId;
  final DateTime date;
  final int xpGained;
  final int tasksCompleted;
  final String? category;
  final Map<String, dynamic>? categoryBreakdown;
  final Map<String, dynamic>? taskTypeBreakdown;
  final int streakCount;
  final int levelAtTime;
  final Map<String, dynamic>? additionalMetrics;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProgressEntry({
    required this.id,
    required this.userId,
    required this.date,
    this.xpGained = 0,
    this.tasksCompleted = 0,
    this.category,
    this.categoryBreakdown,
    this.taskTypeBreakdown,
    this.streakCount = 0,
    this.levelAtTime = 1,
    this.additionalMetrics,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProgressEntry.fromJson(Map<String, dynamic> json) =>
      _$ProgressEntryFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressEntryToJson(this);

  ProgressEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? xpGained,
    int? tasksCompleted,
    String? category,
    Map<String, dynamic>? categoryBreakdown,
    Map<String, dynamic>? taskTypeBreakdown,
    int? streakCount,
    int? levelAtTime,
    Map<String, dynamic>? additionalMetrics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgressEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      xpGained: xpGained ?? this.xpGained,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      category: category ?? this.category,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      taskTypeBreakdown: taskTypeBreakdown ?? this.taskTypeBreakdown,
      streakCount: streakCount ?? this.streakCount,
      levelAtTime: levelAtTime ?? this.levelAtTime,
      additionalMetrics: additionalMetrics ?? this.additionalMetrics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
