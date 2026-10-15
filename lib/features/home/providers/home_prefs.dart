import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';

/// Small per-device UI memories for Home, kept in SharedPreferences (no
/// schema change). All are cleared on logout.
class HomePrefKeys {
  HomePrefKeys._();
  static const snoozed = 'atlas.snoozed.v1';
  static const dayComplete = 'atlas.dayComplete.lastDate';
  static const letterRead = 'atlas.letter.lastReadId';
}

// ─── Snooze ("Later") ───────────────────────────────────────────────

/// itemId → snoozed until. Snoozed items sink to the end of "Up next"
/// until then. Expired entries are pruned on load.
class SnoozeNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(HomePrefKeys.snoozed);
    if (raw == null) return;
    try {
      final now = DateTime.now();
      final map = (jsonDecode(raw) as Map).map(
        (k, v) => MapEntry('$k', DateTime.parse('$v')),
      )..removeWhere((_, until) => !until.isAfter(now));
      state = map;
    } catch (_) {
      await prefs.remove(HomePrefKeys.snoozed);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      HomePrefKeys.snoozed,
      jsonEncode(state.map((k, v) => MapEntry(k, v.toIso8601String()))),
    );
  }

  /// "Later": the next full hour, or 9:00 tomorrow when it's after 21:00.
  static DateTime laterFrom(DateTime now) {
    if (now.hour >= 21) {
      final t = addDays(now, 1);
      return DateTime(t.year, t.month, t.day, 9);
    }
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  Future<void> snooze(String id, {DateTime? until}) async {
    state = {...state, id: until ?? laterFrom(DateTime.now())};
    await _save();
  }

  /// Hide until tomorrow (Skip today).
  Future<void> skipToday(String id) =>
      snooze(id, until: addDays(DateTime.now(), 1));

  /// 9:00 tomorrow.
  Future<void> tomorrow(String id) {
    final t = addDays(DateTime.now(), 1);
    return snooze(id, until: DateTime(t.year, t.month, t.day, 9));
  }

  Future<void> clear(String id) async {
    if (!state.containsKey(id)) return;
    state = {...state}..remove(id);
    await _save();
  }

  bool isSnoozed(String id, DateTime now) => state[id]?.isAfter(now) ?? false;
}

final snoozeProvider =
    NotifierProvider<SnoozeNotifier, Map<String, DateTime>>(SnoozeNotifier.new);

// ─── Day complete ───────────────────────────────────────────────────

/// The last day the "day complete" moment played, so it plays once per day.
class DayCompleteNotifier extends Notifier<String?> {
  @override
  String? build() {
    _load();
    return null;
  }

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _loaded = true;
    state = prefs.getString(HomePrefKeys.dayComplete);
  }

  bool celebratedOn(DateTime day) => state == dayKey(day);

  Future<void> markCelebrated(DateTime day) async {
    state = dayKey(day);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(HomePrefKeys.dayComplete, state!);
  }
}

final dayCompleteProvider =
    NotifierProvider<DayCompleteNotifier, String?>(DayCompleteNotifier.new);

// ─── Letter read ────────────────────────────────────────────────────

/// The id of the last Aurora letter the user opened in full.
class LetterReadNotifier extends Notifier<String?> {
  @override
  String? build() {
    _load();
    return null;
  }

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _loaded = true;
    state = prefs.getString(HomePrefKeys.letterRead) ?? '';
  }

  Future<void> markRead(String id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(HomePrefKeys.letterRead, id);
  }
}

final letterReadProvider =
    NotifierProvider<LetterReadNotifier, String?>(LetterReadNotifier.new);
