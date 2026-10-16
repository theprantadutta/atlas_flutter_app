import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/data/services/local_notification_service.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/notifications/data/inbox.dart';
import 'package:atlas_flutter_app/features/notifications/data/notify_prefs.dart';
import 'package:atlas_flutter_app/features/notifications/scheduling/reminder_plan.dart';
import 'package:atlas_flutter_app/features/progress/providers/progress_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

final _log = AppLog('Notify');

final inboxProvider = Provider<Inbox>((ref) => Inbox(ref.read(notificationDaoProvider)));

/// A route a notification tap asked for, waiting for the app shell to be on
/// screen (a cold start goes through the splash and the auth redirects first).
final pendingNotificationRouteProvider =
    NotifierProvider<PendingRouteNotifier, String?>(PendingRouteNotifier.new);

class PendingRouteNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Open [route] once the shell is up (unknown routes open the inbox).
  void set(String? route) => state = safeNotificationRoute(route);

  void clear() => state = null;
}

/// Only routes the app actually has. Anything else (an old server payload,
/// a typo) opens the inbox instead of an error page.
String safeNotificationRoute(String? route) {
  const known = {
    '/', '/grow', '/aurora', '/aurora/letter', '/world', '/world/achievements',
    '/profile', '/paywall', '/analytics', '/progress', '/notifications',
  };
  return route != null && known.contains(route) ? route : '/notifications';
}

// ─── Reminders ───────────────────────────────────────────────────────

/// Keeps the device's scheduled reminders equal to the plan. Ids below
/// [kUnmanagedIdBase] are the planner's: anything pending there that the plan
/// no longer wants is cancelled, and every planned reminder is (re)scheduled
/// under its stable id.
class ReminderScheduler {
  ReminderScheduler(this._local);
  final LocalNotificationService _local;

  Future<void> apply(List<PlannedReminder> plan) async {
    if (!await _local.hasPermission()) return;
    final wanted = {for (final r in plan) r.id};
    for (final id in await _local.pendingIds()) {
      if (id < kUnmanagedIdBase && !wanted.contains(id)) await _local.cancel(id);
    }
    for (final r in plan) {
      await _local.schedule(
        id: r.id,
        at: r.at,
        title: r.title,
        body: r.body,
        route: r.route,
        channel: switch (r.kind) {
          ReminderKind.habit || ReminderKind.task => NotifyChannel.reminders,
          ReminderKind.morning || ReminderKind.letter => NotifyChannel.daily,
        },
      );
    }
    _log.d('Reminders scheduled: ${plan.length}');
  }

  /// Signed out: nothing should fire for an account that isn't here.
  Future<void> clear() async {
    for (final id in await _local.pendingIds()) {
      if (id < kUnmanagedIdBase) await _local.cancel(id);
    }
  }
}

final reminderSchedulerProvider =
    Provider<ReminderScheduler>((ref) => ReminderScheduler(ref.read(localNotificationServiceProvider)));

/// Re-plans whenever anything the plan depends on changes (habits, tasks,
/// choices, the day), debounced so a burst of edits schedules once. Watch it
/// from the app shell; it also runs on resume via [replanReminders].
final reminderSyncProvider = Provider.autoDispose<void>((ref) {
  final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
  final scheduler = ref.read(reminderSchedulerProvider);
  if (!signedIn) {
    unawaited(scheduler.clear());
    return;
  }
  final prefs = ref.watch(notifyPrefsProvider);
  final habits = ref.watch(habitsStreamProvider);
  final tasks = ref.watch(tasksStreamProvider);
  ref.watch(todayProvider);
  final days = ref.watch(ledgerDaysProvider);
  final name = ref.watch(authProvider.select((s) => s.user?.fullName)) ?? '';
  // Plan only from real data: the stored choices and both lists loaded.
  if (!prefs.loaded || !habits.hasValue || !tasks.hasValue) return;

  final now = DateTime.now();
  final weekAgo = addDays(dateOnly(now), -7);
  final plan = const ReminderPlanner().plan(
    now: now,
    habits: habits.value!,
    tasks: tasks.value!,
    prefs: prefs,
    firstName: name.trim().isEmpty ? null : name.trim().split(RegExp(r'\s+')).first,
    activeThisWeek: days.any((d) => d.xp > 0 && !d.date.isBefore(weekAgo)),
  );
  final timer = Timer(const Duration(milliseconds: 800), () => unawaited(scheduler.apply(plan)));
  ref.onDispose(timer.cancel);
});

/// Force a re-plan (app resumed, permission just granted).
void replanReminders(WidgetRef ref) => ref.invalidate(reminderSyncProvider);

// ─── Inbox: levels and letters ───────────────────────────────────────

/// Files level-ups and new letters. Achievements and discovered places are
/// filed where they are earned (the achievement evaluator, world discovery).
final inboxMomentsProvider = Provider.autoDispose<void>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  if (userId == null) return;
  final inbox = ref.read(inboxProvider);

  // Levels: only once the ledger has loaded (a half-loaded ledger reads as a
  // lower level), and only upward from the highest level already seen here.
  final ledgerReady = ref.watch(progressEntriesStreamProvider).hasValue;
  final level = ref.watch(playerStatsProvider.select((s) => s.level.level));
  if (ledgerReady) unawaited(_fileLevel(inbox, userId, level));

  ref.listen<AsyncValue<AuroraReflection?>>(latestReflectionProvider, (_, next) {
    final letter = next.value;
    if (letter == null) return;
    unawaited(inbox.add(
      userId: userId,
      kind: InboxKind.letter,
      key: 'letter:${letter.id}',
      title: 'Your weekly letter is here',
      body: _firstSentence(letter.content),
      entityType: 'letter',
      entityId: letter.id,
      at: letter.createdAt,
    ));
  }, fireImmediately: true);
});

Future<void> _fileLevel(Inbox inbox, String userId, int level) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'atlas.inbox.level.$userId';
  final seen = prefs.getInt(key);
  if (seen != null && level <= seen) return;
  await prefs.setInt(key, level);
  // The first level seen on this device is where we start, not a moment.
  if (seen == null || level <= 1) return;
  await inbox.add(
    userId: userId,
    kind: InboxKind.level,
    key: 'level:$level',
    title: 'You reached Level $level',
    body: 'Your world grows with you, one small day at a time.',
  );
}

String _firstSentence(String text) {
  final t = text.trim();
  final m = RegExp(r'^.{20,160}?[.!?](\s|$)', dotAll: true).firstMatch(t);
  if (m != null) return m[0]!.trim();
  return t.length <= 140 ? t : '${t.substring(0, 140).trimRight()}…';
}

// ─── Account messages from the server ────────────────────────────────

/// Files an account message (a push, or one fetched from the server) under
/// the server's own id, so the push and the fetch land on the same row.
Future<void> fileAccountMessage(
  Inbox inbox, {
  required String userId,
  required String id,
  required String title,
  required String body,
  DateTime? at,
}) =>
    inbox.add(
      userId: userId,
      id: id,
      kind: InboxKind.account,
      key: 'account:$id',
      title: title,
      body: body,
      at: at,
    );

/// Fetches account messages the device may have missed (no token, the push
/// was swiped away, a new phone). Best effort: offline it simply waits.
Future<void> refreshAccountMessages(ApiService api, Inbox inbox, String userId) async {
  try {
    final res = await api.get('/notifications', queryParameters: {'pageSize': 50});
    final rows = res.data is List ? res.data as List : const [];
    for (final r in rows.whereType<Map>()) {
      final data = r['data'];
      Map? meta;
      try {
        meta = data is String ? jsonDecode(data) as Map? : null;
      } catch (_) {}
      if (meta?['kind'] != InboxKind.account) continue;
      await fileAccountMessage(
        inbox,
        userId: userId,
        id: '${r['id']}',
        title: '${r['title'] ?? ''}',
        body: '${r['body'] ?? ''}',
        at: DateTime.tryParse('${r['created_at']}')?.toLocal(),
      );
    }
  } catch (e) {
    _log.d('Account messages not refreshed: $e');
  }
}
