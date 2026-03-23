import 'package:json_annotation/json_annotation.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';

part 'habit.g.dart';

@JsonSerializable()
class Habit {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final HabitCategory category;
  final HabitFrequency frequency;
  final int difficulty;
  final bool isCompletedToday;
  final int streakCount;
  final int longestStreak;
  final double completionRate;
  final int totalCompletions;
  final String? reminderTime;
  final DateTime? lastCompletedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.frequency,
    this.difficulty = 1,
    this.isCompletedToday = false,
    this.streakCount = 0,
    this.longestStreak = 0,
    this.completionRate = 0.0,
    this.totalCompletions = 0,
    this.reminderTime,
    this.lastCompletedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) => _$HabitFromJson(json);

  Map<String, dynamic> toJson() => _$HabitToJson(this);

  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    HabitCategory? category,
    HabitFrequency? frequency,
    int? difficulty,
    bool? isCompletedToday,
    int? streakCount,
    int? longestStreak,
    double? completionRate,
    int? totalCompletions,
    String? reminderTime,
    DateTime? lastCompletedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      difficulty: difficulty ?? this.difficulty,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      completionRate: completionRate ?? this.completionRate,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      reminderTime: reminderTime ?? this.reminderTime,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
