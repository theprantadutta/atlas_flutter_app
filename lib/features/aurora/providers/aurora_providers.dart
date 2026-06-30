import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';

/// HTTP 402 from the backend means "free limit reached → show the paywall".
const _paywallStatus = 402;

bool _isPaywall(Object error) =>
    error is AppException && error.statusCode == _paywallStatus;

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
      await ref.read(auroraRepositoryProvider).generateReflection(userId);
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
      final result =
          await ref.read(auroraRepositoryProvider).chat(message, trimmedHistory);
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

// ─── Helpers ────────────────────────────────────────────────────────

String _friendly(Object error) {
  if (error is AppException) return error.message;
  return 'Something went wrong. Please try again.';
}
