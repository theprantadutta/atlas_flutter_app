import 'package:json_annotation/json_annotation.dart';

enum TaskType {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('long_term')
  longTerm,
}

enum TaskCategory {
  @JsonValue('work')
  work,
  @JsonValue('health')
  health,
  @JsonValue('learning')
  learning,
  @JsonValue('personal')
  personal,
  @JsonValue('fitness')
  fitness,
  @JsonValue('mindfulness')
  mindfulness,
  @JsonValue('social')
  social,
  @JsonValue('creativity')
  creativity,
}

enum HabitCategory {
  @JsonValue('health')
  health,
  @JsonValue('fitness')
  fitness,
  @JsonValue('learning')
  learning,
  @JsonValue('mindfulness')
  mindfulness,
  @JsonValue('productivity')
  productivity,
  @JsonValue('social')
  social,
  @JsonValue('creativity')
  creativity,
  @JsonValue('personal')
  personal,
}

enum HabitFrequency {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('custom')
  custom,
}

enum GoalCategory {
  @JsonValue('career')
  career,
  @JsonValue('health')
  health,
  @JsonValue('education')
  education,
  @JsonValue('financial')
  financial,
  @JsonValue('personal')
  personal,
  @JsonValue('fitness')
  fitness,
  @JsonValue('social')
  social,
  @JsonValue('creativity')
  creativity,
}

enum GoalPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

enum GoalStatus {
  @JsonValue('not_started')
  notStarted,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('on_hold')
  onHold,
  @JsonValue('cancelled')
  cancelled,
}

enum AchievementType {
  @JsonValue('task_completion')
  taskCompletion,
  @JsonValue('streak')
  streak,
  @JsonValue('level_up')
  levelUp,
  @JsonValue('habit_mastery')
  habitMastery,
  @JsonValue('goal_completion')
  goalCompletion,
  @JsonValue('exploration')
  exploration,
  @JsonValue('social')
  social,
  @JsonValue('special')
  special,
}

enum BadgeTier {
  @JsonValue('bronze')
  bronze,
  @JsonValue('silver')
  silver,
  @JsonValue('gold')
  gold,
  @JsonValue('platinum')
  platinum,
  @JsonValue('diamond')
  diamond,
}

enum WorldTileType {
  @JsonValue('forest')
  forest,
  @JsonValue('mountain')
  mountain,
  @JsonValue('ocean')
  ocean,
  @JsonValue('desert')
  desert,
  @JsonValue('city')
  city,
  @JsonValue('village')
  village,
  @JsonValue('castle')
  castle,
  @JsonValue('ruins')
  ruins,
  @JsonValue('special')
  special,
}

enum AttributeType {
  @JsonValue('strength')
  strength,
  @JsonValue('wisdom')
  wisdom,
  @JsonValue('intelligence')
  intelligence,
}

enum AuthProvider {
  @JsonValue('email')
  email,
  @JsonValue('google')
  google,
}

enum SyncOperationType {
  @JsonValue('create')
  create,
  @JsonValue('update')
  update,
  @JsonValue('delete')
  delete,
}
