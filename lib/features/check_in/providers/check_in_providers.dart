import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_companion_providers.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_preferences_provider.dart';
import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart'
    show todayProvider;
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(ref.read(checkInDaoProvider));
});

/// Today's check-ins (at most one morning and one evening), morning first.
final todayCheckInsProvider =
    StreamProvider.autoDispose<List<CheckIn>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final today = ref.watch(todayProvider);
  return ref.read(checkInRepositoryProvider).watchDay(userId, today);
});

/// Check-ins for local days in [start, end), oldest first, one per moment.
final checkInsInRangeProvider = StreamProvider.autoDispose
    .family<List<CheckIn>, ({DateTime start, DateTime end})>((ref, range) {
  final userId = ref.watch(currentUserIdProvider);
  return ref
      .read(checkInRepositoryProvider)
      .watchRange(userId, range.start, range.end);
});

/// The Insights mood strip: 7 entries for the 7 days ending today (oldest
/// first), each the day's latest mood or null when there was no check-in.
final weekMoodsProvider = Provider.autoDispose<List<int?>>((ref) {
  final today = ref.watch(todayProvider);
  final start = addDays(today, -6);
  final rows = ref
          .watch(checkInsInRangeProvider(
              (start: start, end: addDays(today, 1))))
          .value ??
      const <CheckIn>[];
  return moodStrip(rows, start, 7);
});

/// The latest mood per day for [days] days from [start] (pure, for tests).
List<int?> moodStrip(List<CheckIn> rows, DateTime start, int days) {
  final byDay = <String, CheckIn>{};
  for (final c in rows) {
    final k = dayKey(c.date);
    final prev = byDay[k];
    // Evening over morning; then the most recently updated.
    if (prev == null ||
        (c.moment == 'evening' && prev.moment != 'evening') ||
        (c.moment == prev.moment && c.updatedAt.isAfter(prev.updatedAt))) {
      byDay[k] = c;
    }
  }
  return [
    for (var i = 0; i < days; i++) byDay[dayKey(addDays(start, i))]?.mood,
  ];
}

// ─── When the Home card shows ───────────────────────────────────────

/// The moment the check-in card should offer at [now], or null: morning
/// before 12:00, evening from 17:00, never once that moment is done or was
/// dismissed for the day.
CheckInMoment? dueCheckInMoment(
  DateTime now, {
  required Set<CheckInMoment> done,
  Set<CheckInMoment> dismissed = const {},
}) {
  final CheckInMoment moment;
  if (now.hour < 12) {
    moment = CheckInMoment.morning;
  } else if (now.hour >= 17) {
    moment = CheckInMoment.evening;
  } else {
    return null;
  }
  if (done.contains(moment) || dismissed.contains(moment)) return null;
  return moment;
}

/// Moments the user dismissed today (stored per user and day on the device).
class CheckInDismissalsNotifier extends Notifier<Set<CheckInMoment>> {
  static String _key(String userId) => 'check_in_dismissed_$userId';

  @override
  Set<CheckInMoment> build() {
    final userId = ref.watch(currentUserIdProvider);
    final today = ref.watch(todayProvider);
    _load(userId, today);
    return const {};
  }

  Future<void> _load(String userId, DateTime today) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key(userId)) ?? const [];
      final prefix = '${dayKey(today)}|';
      if (!ref.mounted) return;
      state = {
        for (final e in raw)
          if (e.startsWith(prefix))
            CheckInMoment.fromWire(e.substring(prefix.length)),
      };
    } catch (_) {/* a missing preference just means nothing dismissed */}
  }

  /// Hide the card for [moment] until tomorrow.
  Future<void> dismiss(CheckInMoment moment) async {
    state = {...state, moment};
    final userId = ref.read(currentUserIdProvider);
    final today = dayKey(ref.read(todayProvider));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key(userId), [
        // Only today's entries are kept.
        for (final m in state) '$today|${m.wire}',
      ]);
    } catch (_) {/* best effort */}
  }
}

final checkInDismissalsProvider =
    NotifierProvider<CheckInDismissalsNotifier, Set<CheckInMoment>>(
        CheckInDismissalsNotifier.new);

/// The moment the Home check-in card should show right now, or null to hide
/// it. Re-evaluated whenever today's check-ins or dismissals change; the UI
/// can `ref.invalidate` it on resume to pick up the clock.
final checkInPromptProvider = Provider.autoDispose<CheckInMoment?>((ref) {
  final rows = ref.watch(todayCheckInsProvider).value ?? const <CheckIn>[];
  final dismissed = ref.watch(checkInDismissalsProvider);
  return dueCheckInMoment(
    DateTime.now(),
    done: {for (final c in rows) CheckInMoment.fromWire(c.moment)},
    dismissed: dismissed,
  );
});

// ─── Saving a check-in (and asking for a reply) ─────────────────────

/// Why a check-in has no reply from Aurora.
enum CheckInReplyMiss {
  /// 402: replies are part of Atlas Aurora (free weekly replies used up).
  premium,

  /// No connection.
  offline,

  /// Anything else (server error).
  failed,
}

class CheckInState {
  const CheckInState({
    this.saving = false,
    this.awaitingReply = false,
    this.checkIn,
    this.reply,
    this.replyMiss,
    this.freeRepliesLeft,
  });

  final bool saving;

  /// Saved locally, waiting for Aurora's reply.
  final bool awaitingReply;

  /// The saved row (always present after a save, whatever the network did).
  final CheckIn? checkIn;
  final String? reply;
  final CheckInReplyMiss? replyMiss;
  final int? freeRepliesLeft;

  /// Show the quiet "Aurora's replies are part of Atlas Aurora" line (no
  /// paywall push): the reply was refused (402) or couldn't be fetched
  /// offline.
  bool get showRepliesArePremiumLine =>
      replyMiss == CheckInReplyMiss.premium ||
      replyMiss == CheckInReplyMiss.offline;
}

class CheckInController extends Notifier<CheckInState> {
  @override
  CheckInState build() => const CheckInState();

  /// Saves the check-in locally FIRST (it always lands, offline or not), then
  /// asks Aurora for a short reply and keeps it on the row. A 402 or no
  /// connection just means no reply ([CheckInState.replyMiss]).
  Future<CheckIn?> save({
    required int mood,
    required CheckInMoment moment,
    String? note,
  }) async {
    if (state.saving || state.awaitingReply) return null;
    state = const CheckInState(saving: true);
    final userId = ref.read(currentUserIdProvider);
    final repo = ref.read(checkInRepositoryProvider);

    final row = await repo.save(
        userId: userId, moment: moment, mood: mood, note: note);
    state = CheckInState(checkIn: row, awaitingReply: true);

    try {
      final context = await buildAuroraContext(ref);
      final res = await ref.read(auroraRepositoryProvider).checkInReply(
            mood: row.mood,
            note: row.note,
            moment: row.moment,
            context: context,
            preferences: ref.read(auroraPreferencesProvider).toWire(),
          );
      if (res.reply.isEmpty) {
        state = CheckInState(
            checkIn: row,
            replyMiss: CheckInReplyMiss.failed,
            freeRepliesLeft: res.freeRepliesLeft);
        return row;
      }
      await repo.setReply(row.id, res.reply);
      state = CheckInState(
        checkIn: await repo.getById(row.id) ?? row,
        reply: res.reply,
        freeRepliesLeft: res.freeRepliesLeft,
      );
    } catch (e) {
      state = CheckInState(checkIn: row, replyMiss: _missFor(e));
    }
    return row;
  }

  static CheckInReplyMiss _missFor(Object e) {
    if (e is AppException && e.statusCode == 402) {
      return CheckInReplyMiss.premium;
    }
    if (e is NetworkException) return CheckInReplyMiss.offline;
    return CheckInReplyMiss.failed;
  }

  /// Forget the last save (e.g. when the card closes).
  void reset() => state = const CheckInState();
}

final checkInControllerProvider =
    NotifierProvider<CheckInController, CheckInState>(CheckInController.new);
