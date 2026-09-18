import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_preferences_provider.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/goals/providers/goal_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';

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
  });

  final ChatRole role;
  final String content;
  final bool pending;
  final List<AuroraCreatedEntity> created;
}

class AuroraChatState {
  const AuroraChatState({
    this.messages = const [],
    this.sending = false,
    this.error,
    this.needsPaywall = false,
  });

  final List<ChatMessage> messages;
  final bool sending;
  final String? error;
  final bool needsPaywall;

  AuroraChatState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    String? error,
    bool? needsPaywall,
    bool clearError = false,
    bool clearPaywall = false,
  }) {
    return AuroraChatState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      error: clearError ? null : (error ?? this.error),
      needsPaywall: clearPaywall ? false : (needsPaywall ?? this.needsPaywall),
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

    try {
      final result = await ref.read(auroraRepositoryProvider).chat(
            message,
            trimmedHistory,
            preferences: ref.read(auroraPreferencesProvider).toWire(),
          );
      // Create any parsed entities in local Drift (offline-first source of truth).
      await applyAuroraCreations(ref, result.created);
      _replacePending(ChatMessage(
        role: ChatRole.aurora,
        content: result.reply,
        created: result.created,
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
