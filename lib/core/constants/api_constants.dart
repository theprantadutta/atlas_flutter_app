import 'package:atlas_flutter_app/core/config/app_config.dart';

class ApiConstants {
  static String get _base => '${AppConfig.baseUrl}${AppConfig.apiPrefix}';

  // Auth
  static String get authRegister => '$_base/auth/register';
  static String get authLogin => '$_base/auth/login';
  static String get authGoogle => '$_base/auth/google';
  static String get authRefresh => '$_base/auth/refresh';
  static String get authLogout => '$_base/auth/logout';
  static String get authMe => '$_base/auth/me';

  // Tasks
  static String get tasks => '$_base/tasks';
  static String taskById(String id) => '$_base/tasks/$id';
  static String taskComplete(String id) => '$_base/tasks/$id/complete';
  static String get tasksBatchComplete => '$_base/tasks/batch-complete';
  static String get tasksStats => '$_base/tasks/stats';
  static String get tasksTrend => '$_base/tasks/trend';

  // Habits
  static String get habits => '$_base/habits';
  static String habitById(String id) => '$_base/habits/$id';
  static String habitComplete(String id) => '$_base/habits/$id/complete';

  // Goals
  static String get goals => '$_base/goals';
  static String goalById(String id) => '$_base/goals/$id';
  static String goalProgress(String id) => '$_base/goals/$id/progress';
  static String get goalsOverdue => '$_base/goals/overdue';
  static String get goalsDueSoon => '$_base/goals/due-soon';

  // Avatar
  static String get avatar => '$_base/avatar';
  static String get avatarAppearance => '$_base/avatar/appearance';
  static String get avatarUnlockItem => '$_base/avatar/unlock-item';
  static String get avatarStats => '$_base/avatar/stats';

  // Achievements
  static String get achievements => '$_base/achievements';
  static String get achievementsRecent => '$_base/achievements/recent';
  static String get achievementsCheck => '$_base/achievements/check';

  // World
  static String get worldTiles => '$_base/world/tiles';
  static String worldTileUnlock(String id) => '$_base/world/tiles/$id/unlock';
  static String get worldStats => '$_base/world/stats';
  static String get worldSeed => '$_base/world/seed';

  // Progress
  static String get progress => '$_base/progress';
  static String get progressTrend => '$_base/progress/trend';
  static String get progressCategories => '$_base/progress/categories';

  // Analytics
  static String get analyticsDashboard => '$_base/analytics/dashboard';

  // Notifications
  static String get notifications => '$_base/notifications';
  static String notificationById(String id) => '$_base/notifications/$id';
  static String notificationMarkRead(String id) =>
      '$_base/notifications/$id/read';
  static String get notificationsReadAll => '$_base/notifications/read-all';
  static String get notificationsUnreadCount =>
      '$_base/notifications/unread-count';

  // Device Tokens
  static String get deviceTokens => '$_base/device-tokens';

  // Sync
  static String get syncPush => '$_base/sync/push';
  static String get syncPull => '$_base/sync/pull';
}
