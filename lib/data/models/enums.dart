import 'package:json_annotation/json_annotation.dart';

// All enums must match the backend's Atlas.Domain.Enums exactly.
// The backend uses JsonStringEnumConverter with SnakeCaseLower policy.

enum TaskType {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('long_term')
  longTerm,
}

enum TaskCategory {
  @JsonValue('health')
  health,
  @JsonValue('fitness')
  fitness,
  @JsonValue('mindfulness')
  mindfulness,
  @JsonValue('finance')
  finance,
  @JsonValue('work')
  work,
  @JsonValue('learning')
  learning,
  @JsonValue('social')
  social,
  @JsonValue('creative')
  creative,
  @JsonValue('custom')
  custom,
}

enum HabitCategory {
  @JsonValue('health')
  health,
  @JsonValue('fitness')
  fitness,
  @JsonValue('mindfulness')
  mindfulness,
  @JsonValue('learning')
  learning,
  @JsonValue('creative')
  creative,
  @JsonValue('social')
  social,
  @JsonValue('productivity')
  productivity,
  @JsonValue('custom')
  custom,
}

enum HabitFrequency {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('weekdays')
  weekdays,
  @JsonValue('weekends')
  weekends,
  @JsonValue('custom')
  custom,
}

enum GoalCategory {
  @JsonValue('health')
  health,
  @JsonValue('fitness')
  fitness,
  @JsonValue('mindfulness')
  mindfulness,
  @JsonValue('learning')
  learning,
  @JsonValue('career')
  career,
  @JsonValue('financial')
  financial,
  @JsonValue('relationships')
  relationships,
  @JsonValue('personal')
  personal,
  @JsonValue('custom')
  custom,
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
  @JsonValue('on_hold')
  onHold,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

enum AchievementType {
  @JsonValue('streak')
  streak,
  @JsonValue('total')
  total,
  @JsonValue('milestone')
  milestone,
  @JsonValue('category')
  category,
  @JsonValue('level')
  level,
  @JsonValue('special')
  special,
}

enum BadgeTier {
  @JsonValue('bronze')
  bronze,
  @JsonValue('common')
  common,
  @JsonValue('rare')
  rare,
  @JsonValue('epic')
  epic,
  @JsonValue('legendary')
  legendary,
}

enum WorldTileType {
  @JsonValue('grass')
  grass,
  @JsonValue('forest')
  forest,
  @JsonValue('mountain')
  mountain,
  @JsonValue('water')
  water,
  @JsonValue('desert')
  desert,
  @JsonValue('city')
  city,
  @JsonValue('building')
  building,
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
