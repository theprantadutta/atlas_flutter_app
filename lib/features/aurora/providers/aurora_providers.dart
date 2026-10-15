import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/core/utils/prose.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_repository.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_preferences_provider.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/goals/providers/goal_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

/// HTTP 402 from the backend means "free limit reached → show the paywall".
const _paywallStatus = 402;

bool _isPaywall(Object error) =>
    error is AppException && error.statusCode == _paywallStatus;

// ─── Applying Aurora-parsed entities to local Drift (offline-first) ─

/// Create Aurora's parsed specs in the local Drift database (the source of
/// truth), marked dirty for later sync. The backend only parses — creation is
/// always local, so quick-add works fully offline and never double-creates.
/// Returns the number of entities created.
Future<int> applyAuroraCreations(
    Ref ref, List<AuroraCreatedEntity> created) async {
  if (created.isEmpty) return 0;
  final userId = ref.read(currentUserIdProvider);
  final tasks = ref.read(taskActionsProvider);
  final habits = ref.read(habitActionsProvider);
  final goals = ref.read(goalActionsProvider);

  var count = 0;
  for (final e in created) {
    switch (e.type) {
      case 'habit':
        await habits.create(
          userId: userId,
          title: e.title,
          note: e.description,
          category: _normCategory(e.category, 'custom'),
          frequency: _normFrequency(e.frequency),
        );
        count++;
      case 'task':
        await tasks.create(
          userId: userId,
          title: e.title,
          note: e.description,
          category: _normCategory(e.category, 'custom'),
          type: _normTaskType(e.taskType),
          xp: _xpForDifficulty(e.difficulty),
        );
        count++;
      case 'goal':
        await goals.create(
          userId: userId,
          title: e.title,
          category: _normCategory(e.category, 'personal'),
        );
        count++;
    }
  }
  return count;
}

String _normCategory(String? c, String fallback) {
  final v = (c ?? '').trim().toLowerCase();
  return v.isEmpty ? fallback : v;
}

String _normFrequency(String? f) =>
    (f ?? '').toLowerCase() == 'weekly' ? 'weekly' : 'daily';

String _normTaskType(String? t) {
  switch ((t ?? '').toLowerCase()) {
    case 'weekly':
      return 'weekly';
    case 'longterm':
    case 'long_term':
      return 'longTerm';
    default:
      return 'daily';
  }
}

int _xpForDifficulty(int? d) {
  final v = (d ?? 3).clamp(1, 10);
  return 15 + v * 5; // 20..65
}

// ─── Latest cached reflection (Drift stream) ────────────────────────

final latestReflectionProvider =
    StreamProvider.autoDispose<AuroraReflection?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref.read(auroraRepositoryProvider).watchLatestReflection(userId);
});

// ─── Reflection generation ──────────────────────────────────────────

class ReflectionGenState {
  const ReflectionGenState({
    this.generating = false,
    this.error,
    this.needsPaywall = false,
  });

  final bool generating;
  final String? error;
  final bool needsPaywall;

  ReflectionGenState copyWith({
    bool? generating,
    String? error,
    bool? needsPaywall,
    bool clearError = false,
    bool clearPaywall = false,
  }) {
    return ReflectionGenState(
      generating: generating ?? this.generating,
      error: clearError ? null : (error ?? this.error),
      needsPaywall: clearPaywall ? false : (needsPaywall ?? this.needsPaywall),
    );
  }
}

class ReflectionGenNotifier extends Notifier<ReflectionGenState> {
  @override
  ReflectionGenState build() => const ReflectionGenState();

  /// Generate a fresh reflection. Returns true on success. On the free weekly
  /// limit, sets [ReflectionGenState.needsPaywall] and returns false.
  Future<bool> generate() async {
    if (state.generating) return false;
    state = state.copyWith(
        generating: true, clearError: true, clearPaywall: true);
    final userId = ref.read(currentUserIdProvider);
    try {
      await ref.read(auroraRepositoryProvider).generateReflection(
            userId,
            preferences: ref.read(auroraPreferencesProvider).toWire(),
          );
      state = state.copyWith(generating: false);
      return true;
    } catch (e) {
      if (_isPaywall(e)) {
        state = state.copyWith(generating: false, needsPaywall: true);
      } else {
        state = state.copyWith(
            generating: false, error: _friendly(e));
      }
      return false;
    } finally {
      // Usage changed (or the limit was hit) — refresh the meter.
      ref.read(entitlementsProvider.notifier).refresh();
    }
  }

  void clearPaywall() => state = state.copyWith(clearPaywall: true);
}

final reflectionGenProvider =
    NotifierProvider<ReflectionGenNotifier, ReflectionGenState>(
        ReflectionGenNotifier.new);

// ─── Chat ───────────────────────────────────────────────────────────

enum ChatRole { user, aurora }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.pending = false,
    this.created = const [],
    this.suggestions = const [],
    this.followUps = const [],
    this.fresh = false,
  });

  final ChatRole role;
  final String content;
  final bool pending;
  final List<AuroraCreatedEntity> created;
  final List<AuroraSuggestion> suggestions;
  final List<String> followUps;

  /// Just arrived: reveal it in chunks and stagger its cards in.
  final bool fresh;
}

class AuroraChatState {
  const AuroraChatState({
    this.messages = const [],
    this.sending = false,
    this.error,
    this.needsPaywall = false,
    this.done = const {},
  });

  final List<ChatMessage> messages;
  final bool sending;
  final String? error;
  final bool needsPaywall;

  /// Suggestions already added or reminded, keyed by [suggestionKey].
  final Set<String> done;

  static String suggestionKey(int messageIndex, AuroraSuggestion s) =>
      '$messageIndex:${s.title}';

  /// The follow-up chips to show: the last reply's, else the defaults.
  List<String> get quickReplies {
    for (final m in messages.reversed) {
      if (m.role == ChatRole.aurora && !m.pending) {
        return m.followUps.isNotEmpty ? m.followUps : const ['Plan tomorrow', 'Why am I tired?'];
      }
    }
    return const ['Plan tomorrow', 'Why am I tired?'];
  }

  AuroraChatState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    String? error,
    bool? needsPaywall,
    bool clearError = false,
    bool clearPaywall = false,
    Set<String>? done,
  }) {
    return AuroraChatState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      error: clearError ? null : (error ?? this.error),
      needsPaywall: clearPaywall ? false : (needsPaywall ?? this.needsPaywall),
      done: done ?? this.done,
    );
  }
}

class AuroraChatNotifier extends Notifier<AuroraChatState> {
  @override
  AuroraChatState build() => const AuroraChatState();

  /// Recent turns sent as context (cap to keep the prompt small).
  static const _historyWindow = 10;

  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.sending) return;

    final history = state.messages
        .where((m) => !m.pending)
        .map((m) => {
              'role': m.role == ChatRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();
    final trimmedHistory = history.length > _historyWindow
        ? history.sublist(history.length - _historyWindow)
        : history;

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(role: ChatRole.user, content: message),
        const ChatMessage(role: ChatRole.aurora, content: '', pending: true),
      ],
      sending: true,
      clearError: true,
      clearPaywall: true,
    );

    final repo = ref.read(auroraRepositoryProvider);
    final prefs = ref.read(auroraPreferencesProvider).toWire();
    try {
      AuroraChatResult? result;
      var streamed = false;
      try {
        // Stream so words appear as Aurora writes them.
        var text = '';
        await for (final e in repo.chatStream(message, trimmedHistory, preferences: prefs)) {
          switch (e) {
            case AuroraStreamDelta(text: final chunk):
              text += chunk;
              streamed = true;
              _updatePending(stripLongDashes(text));
            case AuroraStreamDone(result: final r):
              result = r;
          }
        }
      } on AppException catch (e) {
        // Servers without the stream endpoint (404/405): use the one-shot call.
        if (!streamed && (e.statusCode == 404 || e.statusCode == 405)) {
          result = await repo.chat(message, trimmedHistory, preferences: prefs);
        } else {
          rethrow;
        }
      }
      final done = result!;
      // Create any parsed entities in local Drift (offline-first source of truth).
      await applyAuroraCreations(ref, done.created);
      _replacePending(ChatMessage(
        role: ChatRole.aurora,
        content: done.reply,
        created: done.created,
        suggestions: done.suggestions,
        followUps: done.followUps,
        // A streamed reply was already revealed word by word.
        fresh: !streamed,
      ));
      state = state.copyWith(sending: false);
    } catch (e) {
      _removePending();
      if (_isPaywall(e)) {
        state = state.copyWith(sending: false, needsPaywall: true);
      } else {
        state = state.copyWith(sending: false, error: _friendly(e));
      }
    } finally {
      // A chat turn consumes weekly quota — refresh the usage meter.
      ref.read(entitlementsProvider.notifier).refresh();
    }
  }

  /// Show the reply so far in the pending bubble.
  void _updatePending(String text) {
    final next = [...state.messages];
    final idx = next.lastIndexWhere((m) => m.pending);
    if (idx < 0) return;
    next[idx] = ChatMessage(role: ChatRole.aurora, content: text, pending: true);
    state = state.copyWith(messages: next);
  }

  void _replacePending(ChatMessage replacement) {
    final next = [...state.messages];
    final idx = next.lastIndexWhere((m) => m.pending);
    if (idx >= 0) {
      next[idx] = replacement;
    } else {
      next.add(replacement);
    }
    state = state.copyWith(messages: next);
  }

  void _removePending() {
    state =
        state.copyWith(messages: state.messages.where((m) => !m.pending).toList());
  }

  void clearPaywall() => state = state.copyWith(clearPaywall: true);
  void clearError() => state = state.copyWith(clearError: true);

  /// Add a suggested habit or task to Grow, locally (offline-first).
  Future<void> addSuggestion(int messageIndex, AuroraSuggestion s) async {
    final key = AuroraChatState.suggestionKey(messageIndex, s);
    if (state.done.contains(key)) return;
    state = state.copyWith(done: {...state.done, key});
    final userId = ref.read(currentUserIdProvider);
    final category = _normCategory(s.category, 'custom');
    if (s.kind == 'habit') {
      await ref.read(habitActionsProvider).create(
            userId: userId,
            title: s.title,
            category: category,
            reminderTime: s.time,
          );
    } else {
      await ref.read(taskActionsProvider).create(
            userId: userId,
            title: s.title,
            category: category,
            xp: s.xp ?? 15,
            dueTime: s.time,
          );
    }
  }

  /// "Remind me": one gentle local notification in two hours.
  Future<void> remind(int messageIndex, AuroraSuggestion s) async {
    final key = AuroraChatState.suggestionKey(messageIndex, s);
    if (state.done.contains(key)) return;
    state = state.copyWith(done: {...state.done, key});
    final notifications = ref.read(localNotificationServiceProvider);
    await notifications.requestPermissions();
    await notifications.scheduleOnce(
      id: s.title.hashCode & 0x7fffffff,
      title: s.title,
      body: 'A small kindness Aurora suggested earlier.',
      at: DateTime.now().add(const Duration(hours: 2)),
      payload: '/aurora',
    );
  }

  /// Start a new conversation.
  void reset() => state = const AuroraChatState();

  /// The reply at [index] has finished revealing; don't animate it again.
  void markRevealed(int index) {
    if (index < 0 || index >= state.messages.length || !state.messages[index].fresh) return;
    final m = state.messages[index];
    final next = [...state.messages];
    next[index] = ChatMessage(
      role: m.role,
      content: m.content,
      created: m.created,
      suggestions: m.suggestions,
      followUps: m.followUps,
    );
    state = state.copyWith(messages: next);
  }
}

final auroraChatProvider =
    NotifierProvider<AuroraChatNotifier, AuroraChatState>(
        AuroraChatNotifier.new);

// ─── Natural-language quick-add ─────────────────────────────────────

class QuickAddState {
  const QuickAddState({
    this.submitting = false,
    this.result,
    this.error,
    this.needsPaywall = false,
  });

  final bool submitting;
  final AuroraQuickAddResult? result;
  final String? error;
  final bool needsPaywall;
}

class QuickAddNotifier extends Notifier<QuickAddState> {
  @override
  QuickAddState build() => const QuickAddState();

  /// Parse [text] on the backend, then create the specs in local Drift.
  /// Returns true on success. On the premium gate, sets [needsPaywall].
  Future<bool> submit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.submitting) return false;
    state = const QuickAddState(submitting: true);
    try {
      final res = await ref.read(auroraRepositoryProvider).quickAdd(trimmed);
      await applyAuroraCreations(ref, res.created);
      state = QuickAddState(result: res);
      return true;
    } catch (e) {
      if (_isPaywall(e)) {
        state = const QuickAddState(needsPaywall: true);
      } else {
        state = QuickAddState(error: _friendly(e));
      }
      return false;
    }
  }

  void reset() => state = const QuickAddState();
}

final quickAddProvider =
    NotifierProvider<QuickAddNotifier, QuickAddState>(QuickAddNotifier.new);

// ─── Helpers ────────────────────────────────────────────────────────

String _friendly(Object error) {
  if (error is AppException) return error.message;
  return 'Something went wrong. Please try again.';
}
