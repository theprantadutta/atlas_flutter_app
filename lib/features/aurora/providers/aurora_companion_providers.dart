import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_context.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_conversation_repository.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_memory_repository.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/aurora/data/year_in_review.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_preferences_provider.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart'
    show applyAuroraCreations;
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

final _log = AppLog('Aurora');

/// HTTP 402: premium only, or the free limit is reached.
bool isAuroraPaywall(Object error) =>
    error is AppException && error.statusCode == 402;

String auroraFriendlyError(Object error) {
  if (error is AppException) return error.message;
  return 'Something went wrong. Please try again.';
}

// ─── Context ────────────────────────────────────────────────────────

final auroraContextBuilderProvider = Provider<AuroraContextBuilder>((ref) {
  return AuroraContextBuilder(ref.read(databaseProvider));
});

/// The `context` for the current user, built from Drift. Memories are only
/// included when the user is premium on this device. Never throws: on any
/// local failure the request goes without context (the server falls back to
/// its own snapshot).
Future<Map<String, dynamic>?> buildAuroraContext(
  Ref ref, {
  AuroraContextPeriod period = AuroraContextPeriod.week,
}) async {
  try {
    return await ref.read(auroraContextBuilderProvider).build(
          userId: ref.read(currentUserIdProvider),
          includeMemories: ref.read(isPremiumProvider),
          period: period,
        );
  } catch (e) {
    _log.w('Aurora context could not be built', error: e);
    return null;
  }
}

// ─── Conversations (local only) ─────────────────────────────────────

final auroraConversationRepositoryProvider =
    Provider<AuroraConversationRepository>((ref) {
  return AuroraConversationRepository(ref.read(auroraConversationDaoProvider));
});

/// The history sheet: conversations, most recently updated first.
final auroraConversationsProvider =
    StreamProvider.autoDispose<List<AuroraConversation>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref
      .read(auroraConversationRepositoryProvider)
      .watchConversations(userId);
});

// ─── Memories (local only, premium) ─────────────────────────────────

final auroraMemoryRepositoryProvider = Provider<AuroraMemoryRepository>((ref) {
  return AuroraMemoryRepository(ref.read(auroraMemoryDaoProvider));
});

/// "What Aurora remembers", newest first.
final auroraMemoriesProvider =
    StreamProvider.autoDispose<List<AuroraMemory>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref.read(auroraMemoryRepositoryProvider).watch(userId);
});

/// Memory mutations for the current user.
class AuroraMemoryActions {
  AuroraMemoryActions(this._ref);
  final Ref _ref;

  AuroraMemoryRepository get _repo => _ref.read(auroraMemoryRepositoryProvider);
  String get _userId => _ref.read(currentUserIdProvider);

  /// "Add your own".
  Future<AuroraMemory?> add(String text,
          {AuroraMemorySource source = AuroraMemorySource.you}) =>
      _repo.add(_userId, text, source: source);

  Future<void> delete(String id) => _repo.delete(id);

  /// Undo for [delete].
  Future<void> restore(AuroraMemory memory) => _repo.restore(memory);

  Future<void> clearAll() => _repo.clear(_userId);
}

final auroraMemoryActionsProvider =
    Provider<AuroraMemoryActions>((ref) => AuroraMemoryActions(ref));

// ─── Plan my day (premium) ──────────────────────────────────────────

class PlanDayState {
  const PlanDayState({
    this.loading = false,
    this.energy,
    this.plan,
    this.error,
    this.needsPaywall = false,
  });

  final bool loading;
  final AuroraEnergy? energy;

  /// Picks and set-aside ids, already filtered to items that exist locally.
  /// Picks can be empty (show the message only). Nothing is modified
  /// automatically: the sheet lets the user tend picks.
  final AuroraDayPlan? plan;
  final String? error;
  final bool needsPaywall;
}

class PlanDayController extends Notifier<PlanDayState> {
  @override
  PlanDayState build() => const PlanDayState();

  /// Ask Aurora for 2 to 4 picks for today. Returns true on success; a 402
  /// sets [PlanDayState.needsPaywall].
  Future<bool> request({required AuroraEnergy energy, String? note}) async {
    if (state.loading) return false;
    state = PlanDayState(loading: true, energy: energy);
    try {
      // The server needs the context (400 without it): it is the only list
      // of items Aurora may pick from.
      final context = await buildAuroraContext(ref);
      if (context == null) {
        throw const AppException(
            'Aurora couldn’t read your day just now. Please try again.');
      }
      final plan = await ref.read(auroraRepositoryProvider).planDay(
            energy: energy.wire,
            note: _blankToNull(note),
            context: context,
            preferences: ref.read(auroraPreferencesProvider).toWire(),
          );
      state = PlanDayState(
        energy: energy,
        plan: plan.onlyKnown(
          habitIds: _ids(context, 'habits'),
          taskIds: _ids(context, 'tasks'),
        ),
      );
      return true;
    } catch (e) {
      state = isAuroraPaywall(e)
          ? PlanDayState(energy: energy, needsPaywall: true)
          : PlanDayState(energy: energy, error: auroraFriendlyError(e));
      return false;
    }
  }

  void clearPaywall() => state = PlanDayState(energy: state.energy, plan: state.plan);
  void reset() => state = const PlanDayState();
}

final planDayProvider =
    NotifierProvider<PlanDayController, PlanDayState>(PlanDayController.new);

Set<String> _ids(Map<String, dynamic>? context, String key) => {
      for (final e in (context?[key] as List? ?? const []))
        if (e is Map && e['id'] != null) e['id'].toString(),
    };

String? _blankToNull(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

// ─── Break a goal down (premium) ────────────────────────────────────

class GoalStepsState {
  const GoalStepsState({
    this.goalId,
    this.loading = false,
    this.message,
    this.steps = const [],
    this.selected = const {},
    this.adding = false,
    this.added,
    this.error,
    this.needsPaywall = false,
  });

  final String? goalId;
  final bool loading;
  final String? message;
  final List<AuroraGoalStep> steps;

  /// Indexes into [steps] that are ticked (all, by default).
  final Set<int> selected;
  final bool adding;

  /// How many tasks the last [GoalStepsController.addSelected] created.
  final int? added;
  final String? error;
  final bool needsPaywall;

  List<AuroraGoalStep> get selectedSteps => [
        for (var i = 0; i < steps.length; i++)
          if (selected.contains(i)) steps[i],
      ];

  GoalStepsState copyWith({
    Set<int>? selected,
    bool? adding,
    int? added,
  }) =>
      GoalStepsState(
        goalId: goalId,
        message: message,
        steps: steps,
        selected: selected ?? this.selected,
        adding: adding ?? this.adding,
        added: added ?? this.added,
      );
}

class GoalStepsController extends Notifier<GoalStepsState> {
  @override
  GoalStepsState build() => const GoalStepsState();

  /// Ask Aurora for 3 to 5 steps for [goal]. Returns true on success; a 402
  /// sets [GoalStepsState.needsPaywall].
  Future<bool> request(Goal goal) async {
    if (state.loading) return false;
    state = GoalStepsState(goalId: goal.id, loading: true);
    try {
      final context = await buildAuroraContext(ref);
      final res = await ref.read(auroraRepositoryProvider).goalSteps(
            goal: AuroraGoalInput(
              title: AuroraContextBuilder.cleanForPrompt(
                  goal.title, AuroraContextBuilder.maxTitle),
              description: switch (goal.description) {
                final d? when d.trim().isNotEmpty =>
                  AuroraContextBuilder.cleanForPrompt(
                      d, AuroraContextBuilder.maxNote),
                _ => null,
              },
              category: goal.category,
              targetDate: goal.deadline,
              progress: AuroraContextBuilder.normaliseProgress(goal.progress),
            ),
            context: context,
            preferences: ref.read(auroraPreferencesProvider).toWire(),
          );
      state = GoalStepsState(
        goalId: goal.id,
        message: res.message,
        steps: res.steps,
        selected: {for (var i = 0; i < res.steps.length; i++) i},
      );
      return true;
    } catch (e) {
      state = isAuroraPaywall(e)
          ? GoalStepsState(goalId: goal.id, needsPaywall: true)
          : GoalStepsState(goalId: goal.id, error: auroraFriendlyError(e));
      return false;
    }
  }

  void toggle(int index) {
    final next = {...state.selected};
    if (!next.remove(index)) next.add(index);
    state = state.copyWith(selected: next);
  }

  /// Creates [steps] (default: the ticked ones) as tasks in local Drift,
  /// marked dirty for sync, exactly like [applyAuroraCreations]. Returns how
  /// many were created.
  Future<int> addSelected([List<AuroraGoalStep>? steps]) async {
    final chosen = steps ?? state.selectedSteps;
    if (chosen.isEmpty || state.adding) return 0;
    state = state.copyWith(adding: true);
    final n = await applyAuroraCreations(
        ref, [for (final s in chosen) s.toCreation()]);
    state = state.copyWith(adding: false, added: n);
    return n;
  }

  void reset() => state = const GoalStepsState();
}

final goalStepsProvider =
    NotifierProvider<GoalStepsController, GoalStepsState>(
        GoalStepsController.new);

// ─── Year in review (no AI) ─────────────────────────────────────────

/// "Your year" for the given year, computed from Drift.
final yearInReviewProvider =
    FutureProvider.autoDispose.family<YearInReview, int>((ref, year) {
  final userId = ref.watch(currentUserIdProvider);
  return YearInReview.compute(ref.read(databaseProvider), userId, year);
});
