import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the user wants Atlas to tell them, per device: each device schedules
/// its own reminders, so each keeps its own choices. They survive logout,
/// like the theme.
class NotifyPrefs {
  const NotifyPrefs({
    this.habits = true,
    this.tasks = true,
    this.morning = true,
    this.morningHour = 8,
    this.morningMinute = 0,
    this.letter = true,
    this.loaded = false,
  });

  /// At the time set on each habit.
  final bool habits;

  /// At a task's due time, when it has one.
  final bool tasks;

  /// A calm look at the day, at [morningHour]:[morningMinute].
  final bool morning;
  final int morningHour;
  final int morningMinute;

  /// Sunday at the morning time, when Aurora's letter is ready.
  final bool letter;

  /// False until the stored choices have been read; nothing is scheduled
  /// from the defaults in the meantime.
  final bool loaded;

  bool get any => habits || tasks || morning || letter;

  NotifyPrefs copyWith({
    bool? habits,
    bool? tasks,
    bool? morning,
    int? morningHour,
    int? morningMinute,
    bool? letter,
    bool? loaded,
  }) =>
      NotifyPrefs(
        habits: habits ?? this.habits,
        tasks: tasks ?? this.tasks,
        morning: morning ?? this.morning,
        morningHour: morningHour ?? this.morningHour,
        morningMinute: morningMinute ?? this.morningMinute,
        letter: letter ?? this.letter,
        loaded: loaded ?? this.loaded,
      );

  @override
  bool operator ==(Object other) =>
      other is NotifyPrefs &&
      other.habits == habits &&
      other.tasks == tasks &&
      other.morning == morning &&
      other.morningHour == morningHour &&
      other.morningMinute == morningMinute &&
      other.letter == letter &&
      other.loaded == loaded;

  @override
  int get hashCode => Object.hash(habits, tasks, morning, morningHour, morningMinute, letter, loaded);
}

class NotifyPrefsNotifier extends Notifier<NotifyPrefs> {
  static const _prefix = 'atlas.notify.';

  @override
  NotifyPrefs build() {
    _load();
    return const NotifyPrefs();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    const d = NotifyPrefs();
    state = NotifyPrefs(
      habits: p.getBool('${_prefix}habits') ?? d.habits,
      tasks: p.getBool('${_prefix}tasks') ?? d.tasks,
      morning: p.getBool('${_prefix}morning') ?? d.morning,
      morningHour: p.getInt('${_prefix}morningHour') ?? d.morningHour,
      morningMinute: p.getInt('${_prefix}morningMinute') ?? d.morningMinute,
      letter: p.getBool('${_prefix}letter') ?? d.letter,
      loaded: true,
    );
  }

  Future<void> update(NotifyPrefs next) async {
    state = next.copyWith(loaded: true);
    final p = await SharedPreferences.getInstance();
    await p.setBool('${_prefix}habits', next.habits);
    await p.setBool('${_prefix}tasks', next.tasks);
    await p.setBool('${_prefix}morning', next.morning);
    await p.setInt('${_prefix}morningHour', next.morningHour);
    await p.setInt('${_prefix}morningMinute', next.morningMinute);
    await p.setBool('${_prefix}letter', next.letter);
  }
}

final notifyPrefsProvider = NotifierProvider<NotifyPrefsNotifier, NotifyPrefs>(NotifyPrefsNotifier.new);
