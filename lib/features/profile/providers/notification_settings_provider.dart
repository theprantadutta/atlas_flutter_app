import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Notification Settings State ─────────────────────────────────

class NotificationSettingsState {
  final bool taskReminders;
  final bool habitReminders;
  final bool goalDeadlines;
  final bool achievementNotifications;
  final bool dailySummary;

  const NotificationSettingsState({
    this.taskReminders = true,
    this.habitReminders = true,
    this.goalDeadlines = true,
    this.achievementNotifications = true,
    this.dailySummary = false,
  });

  NotificationSettingsState copyWith({
    bool? taskReminders,
    bool? habitReminders,
    bool? goalDeadlines,
    bool? achievementNotifications,
    bool? dailySummary,
  }) {
    return NotificationSettingsState(
      taskReminders: taskReminders ?? this.taskReminders,
      habitReminders: habitReminders ?? this.habitReminders,
      goalDeadlines: goalDeadlines ?? this.goalDeadlines,
      achievementNotifications:
          achievementNotifications ?? this.achievementNotifications,
      dailySummary: dailySummary ?? this.dailySummary,
    );
  }
}

// ─── Notification Settings Notifier ──────────────────────────────

class NotificationSettingsNotifier
    extends Notifier<NotificationSettingsState> {
  static const _prefix = 'atlas_notif_';

  @override
  NotificationSettingsState build() {
    _load();
    return const NotificationSettingsState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettingsState(
      taskReminders: prefs.getBool('${_prefix}taskReminders') ?? true,
      habitReminders: prefs.getBool('${_prefix}habitReminders') ?? true,
      goalDeadlines: prefs.getBool('${_prefix}goalDeadlines') ?? true,
      achievementNotifications:
          prefs.getBool('${_prefix}achievementNotifications') ?? true,
      dailySummary: prefs.getBool('${_prefix}dailySummary') ?? false,
    );
  }

  Future<void> toggle(String key) async {
    final prefs = await SharedPreferences.getInstance();

    switch (key) {
      case 'taskReminders':
        final v = !state.taskReminders;
        state = state.copyWith(taskReminders: v);
        await prefs.setBool('${_prefix}taskReminders', v);
      case 'habitReminders':
        final v = !state.habitReminders;
        state = state.copyWith(habitReminders: v);
        await prefs.setBool('${_prefix}habitReminders', v);
      case 'goalDeadlines':
        final v = !state.goalDeadlines;
        state = state.copyWith(goalDeadlines: v);
        await prefs.setBool('${_prefix}goalDeadlines', v);
      case 'achievementNotifications':
        final v = !state.achievementNotifications;
        state = state.copyWith(achievementNotifications: v);
        await prefs.setBool('${_prefix}achievementNotifications', v);
      case 'dailySummary':
        final v = !state.dailySummary;
        state = state.copyWith(dailySummary: v);
        await prefs.setBool('${_prefix}dailySummary', v);
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
  NotificationSettingsNotifier.new,
);
