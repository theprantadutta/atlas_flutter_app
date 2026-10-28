import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/services/local_notification_service.dart';
import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/core/utils/prose.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_context.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_conversation_repository.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_memory_repository.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_repository.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_companion_providers.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_preferences_provider.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/goals/providers/goal_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/core/telemetry/telemetry.dart';

/// HTTP 402 from the backend means "free limit reached → show the paywall".
bool _isPaywall(Object error) => isAuroraPaywall(error);

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

/// The latest cached monthly letter (premium), or null.
final latestMonthlyReflectionProvider =
    StreamProvider.autoDispose<AuroraReflection?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref
      .read(auroraRepositoryProvider)
      .watchLatestReflection(userId, period: AuroraLetterPeriod.month.wire);
});

/// Which letter to write.
enum AuroraLetterPeriod {
  /// The weekly letter (free users get a weekly allowance).
  week,

  /// The monthly letter: 30 days, longer, premium (402 for free).
  month;

  String get wire => name;
}

// ─── Reflection generation ──────────────────────────────────────────

class ReflectionGenState {
  const ReflectionGenState({
    this.generating = false,
    this.error,
    this.needsPaywall = false,
    this.period = AuroraLetterPeriod.week,
  });

  final bool generating;
  final String? error;
  final bool needsPaywall;

  /// The letter being (or last) generated.
  final AuroraLetterPeriod period;

  ReflectionGenState copyWith({
    bool? generating,
    String? error,
    bool? needsPaywall,
    AuroraLetterPeriod? period,
    bool clearError = false,
    bool clearPaywall = false,
  }) {
    return ReflectionGenState(
      generating: generating ?? this.generating,
      error: clearError ? null : (error ?? this.error),
      needsPaywall: clearPaywall ? false : (needsPaywall ?? this.needsPaywall),
      period: period ?? this.period,
    );
  }
}

class ReflectionGenNotifier extends Notifier<ReflectionGenState> {
  @override
  ReflectionGenState build() => const ReflectionGenState();

  /// Generate a fresh letter for [period] (weekly by default; monthly is
  /// premium). Returns true on success. On the free weekly limit, or a month
  /// letter for a free user, sets [ReflectionGenState.needsPaywall] and
  /// returns false.
  Future<bool> generate({AuroraLetterPeriod period = AuroraLetterPeriod.week}) async {
    if (state.generating) return false;
    state = state.copyWith(
        generating: true, period: period, clearError: true, clearPaywall: true);
    final userId = ref.read(currentUserIdProvider);
    try {
      final context = await buildAuroraContext(
        ref,
        period: period == AuroraLetterPeriod.month
            ? AuroraContextPeriod.month
            : AuroraContextPeriod.week,
      );
      await ref.read(auroraRepositoryProvider).generateReflection(
            userId,
            preferences: ref.read(auroraPreferencesProvider).toWire(),
            context: context,
            period: period.wire,
          );
      Telemetry.letterWritten();
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

  /// The monthly letter (premium).
  Future<bool> generateMonthly() => generate(period: AuroraLetterPeriod.month);

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
    this.id,
    this.pending = false,
    this.created = const [],
    this.suggestions = const [],
    this.followUps = const [],
    this.memoriesProposed = const [],
    this.fresh = false,
  });

  /// The Drift row id, for messages loaded from a saved conversation.
  final String? id;
  final ChatRole role;
  final String content;
  final bool pending;
  final List<AuroraCreatedEntity> created;
  final List<AuroraSuggestion> suggestions;
  final List<String> followUps;

  /// Facts Aurora offers to remember ("Remember this?" chips). Only on the
  /// reply as it arrives; not kept in history.
  final List<String> memoriesProposed;

  /// Just arrived: reveal it in chunks and stagger its cards in.
  final bool fresh;

  ChatMessage copyWith({String? id, bool? fresh}) => ChatMessage(
        id: id ?? this.id,
        role: role,
        content: content,
        pending: pending,
        created: created,
        suggestions: suggestions,
        followUps: followUps,
        memoriesProposed: memoriesProposed,
        fresh: fresh ?? this.fresh,
      );
}

class AuroraChatState {
  const AuroraChatState({
    this.messages = const [],
    this.sending = false,
    this.error,
    this.needsPaywall = false,
    this.done = const {},
    this.conversationId,
    this.memoryChoices = const {},
  });

  final List<ChatMessage> messages;
  final bool sending;
  final String? error;
  final bool needsPaywall;

  /// Suggestions already added or reminded, keyed by [suggestionKey].
  final Set<String> done;

  /// The open conversation, or null for a fresh one (created on first send).
  final String? conversationId;

  /// "Remember this?" chips already answered, keyed by [memoryKey]: true =
  /// saved, false = not now.
  final Map<String, bool> memoryChoices;

  static String suggestionKey(int messageIndex, AuroraSuggestion s) =>
      '$messageIndex:${s.title}';

  static String memoryKey(int messageIndex, String text) =>
      '$messageIndex:$text';

  /// The chips still to show under the message at [messageIndex].
  List<String> openMemories(int messageIndex) {
    if (messageIndex < 0 || messageIndex >= messages.length) return const [];
    return [
      for (final m in messages[messageIndex].memoriesProposed)
        if (!memoryChoices.containsKey(memoryKey(messageIndex, m))) m,
    ];
  }

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
    String? conversationId,
    Map<String, bool>? memoryChoices,
  }) {
    return AuroraChatState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      error: clearError ? null : (error ?? this.error),
      needsPaywall: clearPaywall ? false : (needsPaywall ?? this.needsPaywall),
      done: done ?? this.done,
      conversationId: conversationId ?? this.conversationId,
      memoryChoices: memoryChoices ?? this.memoryChoices,
    );
  }
}

/// Chat with Aurora, backed by the local conversation history: messages are
/// saved as they are sent and received, the screen reopens the most recent
/// conversation if it was updated in the last 12 hours, and the history sent
/// to the server is the last 10 turns of the open conversation.
class AuroraChatNotifier extends Notifier<AuroraChatState> {
  @override
  AuroraChatState build() {
    final userId = ref.watch(currentUserIdProvider);
    Future.microtask(() => _restoreRecent(userId));
    return const AuroraChatState();
  }

  /// Recent turns sent as context (cap to keep the prompt small).
  static const _historyWindow = 10;

  AuroraConversationRepository get _conversations =>
      ref.read(auroraConversationRepositoryProvider);

  /// Reopen the most recent conversation if it is fresh enough. Never
  /// replaces a chat the user has already started.
  Future<void> _restoreRecent(String userId) async {
    try {
      final recent = await _conversations.openRecent(userId);
      if (recent == null || !ref.mounted) return;
      final rows = await _conversations.messagesOf(recent.id);
      if (!ref.mounted ||
          state.messages.isNotEmpty ||
          state.conversationId != null ||
          state.sending) {
        return;
      }
      state = AuroraChatState(
        conversationId: recent.id,
        messages: [for (final m in rows) _fromRow(m)],
      );
    } catch (_) {/* history is a nicety; a fresh chat is fine */}
  }

  static ChatMessage _fromRow(AuroraMessage m) => ChatMessage(
        id: m.id,
        role: m.role == 'user' ? ChatRole.user : ChatRole.aurora,
        content: m.content,
        suggestions: AuroraConversationRepository.suggestionsOf(m),
        followUps: AuroraConversationRepository.followUpsOf(m),
        created: AuroraConversationRepository.createdOf(m),
      );

  /// Open a saved conversation from the history sheet.
  Future<void> openConversation(String conversationId) async {
    if (state.sending) return;
    final rows = await _conversations.messagesOf(conversationId);
    if (!ref.mounted) return;
    state = AuroraChatState(
      conversationId: conversationId,
      messages: [for (final m in rows) _fromRow(m)],
    );
  }

  /// Delete a conversation. Returns what was deleted so the UI can offer
  /// Undo with [restoreConversation]. Deleting the open one starts fresh.
  Future<DeletedConversation?> deleteConversation(String conversationId) async {
    final deleted = await _conversations.delete(conversationId);
    if (ref.mounted && state.conversationId == conversationId && !state.sending) {
      state = const AuroraChatState();
    }
    return deleted;
  }

  /// Undo for [deleteConversation].
  Future<void> restoreConversation(DeletedConversation deleted) =>
      _conversations.restore(deleted);

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

    // Save the user's turn locally first (creating the conversation on the
    // first message). History is a nicety: a failed write never blocks chat.
    final conversationId = await _persistUserTurn(message);

    final repo = ref.read(auroraRepositoryProvider);
    final prefs = ref.read(auroraPreferencesProvider).toWire();
    try {
      final context = await buildAuroraContext(ref);
      AuroraChatResult? result;
      var streamed = false;
      try {
        // Stream so words appear as Aurora writes them.
        var text = '';
        await for (final e in repo.chatStream(message, trimmedHistory,
            preferences: prefs, context: context)) {
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
          result = await repo.chat(message, trimmedHistory,
              preferences: prefs, context: context);
        } else {
          rethrow;
        }
      }
      final done = result!;
      // Create any parsed entities in local Drift (offline-first source of truth).
      await applyAuroraCreations(ref, done.created);
      final saved = await _persistAuroraTurn(conversationId, done);
      _replacePending(ChatMessage(
        id: saved,
        role: ChatRole.aurora,
        content: done.reply,
        created: done.created,
        suggestions: done.suggestions,
        followUps: done.followUps,
        memoriesProposed: done.memoriesProposed,
        // A streamed reply was already revealed word by word.
        fresh: !streamed,
      ));
      Telemetry.auroraMessage(streamed: streamed);
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

  Future<String?> _persistUserTurn(String message) async {
    try {
      var id = state.conversationId;
      if (id == null) {
        final c = await _conversations.create(ref.read(currentUserIdProvider),
            firstMessage: message);
        id = c.id;
        state = state.copyWith(conversationId: id);
      }
      await _conversations.append(id, role: 'user', content: message);
      return id;
    } catch (_) {
      return state.conversationId;
    }
  }

  Future<String?> _persistAuroraTurn(
      String? conversationId, AuroraChatResult r) async {
    if (conversationId == null) return null;
    try {
      final row = await _conversations.append(
        conversationId,
        role: 'aurora',
        content: r.reply,
        suggestions: r.suggestions,
        followUps: r.followUps,
        created: r.created,
      );
      return row.id;
    } catch (_) {
      return null;
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

  /// "Remember this?" → Save: stores the fact locally (source `aurora`).
  /// Nothing is ever saved without this tap.
  Future<void> saveMemory(int messageIndex, String text) async {
    final key = AuroraChatState.memoryKey(messageIndex, text);
    if (state.memoryChoices.containsKey(key)) return;
    state = state.copyWith(memoryChoices: {...state.memoryChoices, key: true});
    await ref
        .read(auroraMemoryActionsProvider)
        .add(text, source: AuroraMemorySource.aurora);
  }

  /// "Remember this?" → Not now.
  void dismissMemory(int messageIndex, String text) {
    final key = AuroraChatState.memoryKey(messageIndex, text);
    if (state.memoryChoices.containsKey(key)) return;
    state = state.copyWith(memoryChoices: {...state.memoryChoices, key: false});
  }

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
    // A one-off: its id sits above the planner's range, so re-planning never
    // cancels it, and is keyed to this suggestion so two never collide.
    await notifications.schedule(
      id: kUnmanagedIdBase + ('$key${DateTime.now().millisecondsSinceEpoch}'.hashCode & 0x0FFFFFFF),
      title: s.title,
      body: 'A small kindness Aurora suggested earlier.',
      at: DateTime.now().add(const Duration(hours: 2)),
      route: '/aurora',
      channel: NotifyChannel.reminders,
    );
  }

  /// Start a new conversation (saved on its first message).
  void reset() {
    if (state.sending) return;
    state = const AuroraChatState();
  }

  /// The reply at [index] has finished revealing; don't animate it again.
  void markRevealed(int index) {
    if (index < 0 || index >= state.messages.length || !state.messages[index].fresh) return;
    final next = [...state.messages];
    next[index] = state.messages[index].copyWith(fresh: false);
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

String _friendly(Object error) => auroraFriendlyError(error);
