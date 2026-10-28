import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_conversation_repository.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_memory_repository.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_companion_providers.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/aurora/screens/aurora_chat_screen.dart';
import 'package:atlas_flutter_app/features/aurora/widgets/conversation_history_sheet.dart';
import 'package:atlas_flutter_app/features/aurora/widgets/goal_steps_sheet.dart';
import 'package:atlas_flutter_app/features/aurora/widgets/plan_day_sheet.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

import '../../helpers/golden.dart';
import '../../helpers/sample_data.dart';

// ─── Fakes ─────────────────────────────────────────────────────────

class _ChatWithMemories extends AuroraChatNotifier {
  @override
  AuroraChatState build() => const AuroraChatState(messages: [
        ChatMessage(role: ChatRole.user, content: 'I am training for a 10k in December'),
        ChatMessage(
          role: ChatRole.aurora,
          content: 'That is a lovely goal. Small runs add up.',
          memoriesProposed: ['Training for a 10k in December', 'Prefers morning runs'],
        ),
      ]);
}

class _FakeMemoryActions extends AuroraMemoryActions {
  _FakeMemoryActions(super.ref);
  final saved = <(String, AuroraMemorySource)>[];

  @override
  Future<AuroraMemory?> add(String text, {AuroraMemorySource source = AuroraMemorySource.you}) async {
    saved.add((text, source));
    return null;
  }
}

class _HistoryChat extends AuroraChatNotifier {
  final opened = <String>[];
  final deleted = <String>[];
  final restored = <String>[];

  @override
  AuroraChatState build() => const AuroraChatState(conversationId: 'c1');

  @override
  Future<void> openConversation(String conversationId) async => opened.add(conversationId);

  @override
  Future<DeletedConversation?> deleteConversation(String conversationId) async {
    deleted.add(conversationId);
    return DeletedConversation(_conversations.firstWhere((c) => c.id == conversationId), const []);
  }

  @override
  Future<void> restoreConversation(DeletedConversation deleted) async =>
      restored.add(deleted.conversation.id);
}

final _now = DateTime(2026, 10, 28, 18);

final _conversations = [
  AuroraConversation(
      id: 'c1', userId: 'u', title: 'Plan my week', createdAt: _now, updatedAt: DateTime(2026, 10, 28, 9, 15)),
  AuroraConversation(
      id: 'c2', userId: 'u', title: 'I feel stuck', createdAt: _now, updatedAt: DateTime(2026, 10, 27, 20)),
  AuroraConversation(
      id: 'c3', userId: 'u', title: 'Celebrate a small win', createdAt: _now, updatedAt: DateTime(2026, 9, 2)),
];

class _FixedPlan extends PlanDayController {
  _FixedPlan(this.fixed);
  final PlanDayState fixed;

  @override
  PlanDayState build() => fixed;
}

class _FixedSteps extends GoalStepsController {
  final added = <List<AuroraGoalStep>>[];

  @override
  GoalStepsState build() => const GoalStepsState(
        goalId: 'g1',
        message: 'Three small steps to start.',
        steps: [
          AuroraGoalStep(title: 'Run 3k without stopping', type: 'weekly', category: 'fitness'),
          AuroraGoalStep(title: 'Buy proper running shoes', type: 'longTerm', category: 'fitness'),
          AuroraGoalStep(title: 'Stretch after every run', type: 'daily', category: 'fitness'),
        ],
        selected: {0, 1, 2},
      );

  @override
  Future<bool> request(Goal goal) async => true;

  @override
  Future<int> addSelected([List<AuroraGoalStep>? steps]) async {
    final chosen = steps ?? state.selectedSteps;
    added.add(chosen);
    state = state.copyWith(added: chosen.length);
    return chosen.length;
  }
}

Widget _sheet(Widget child) => Scaffold(body: SafeArea(child: child));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ─── Remember this? ───

  group('memory chips', () {
    late _FakeMemoryActions actions;

    Future<void> pumpChat(WidgetTester tester) async {
      await pumpPhone(tester, const AuroraChatScreen(), overrides: [
        auroraUsageProvider.overrideWithValue(null),
        onlineProvider.overrideWith((ref) => Stream.value(true)),
        auroraChatProvider.overrideWith(_ChatWithMemories.new),
        auroraMemoryActionsProvider.overrideWith((ref) => actions = _FakeMemoryActions(ref)),
      ]);
      await settle(tester);
    }

    testWidgets('Save stores the fact (from Aurora) and the chip goes', (tester) async {
      await pumpChat(tester);
      expect(find.text('REMEMBER THIS?'), findsNWidgets(2));
      expect(find.text('Training for a 10k in December'), findsOneWidget);

      await tester.tap(find.text('Save').first);
      await settle(tester);

      expect(actions.saved, [('Training for a 10k in December', AuroraMemorySource.aurora)]);
      expect(find.text('Training for a 10k in December'), findsNothing);
      expect(find.text('Prefers morning runs'), findsOneWidget);
      await settle(tester, const Duration(seconds: 5));
    });

    testWidgets('Not now hides it without saving', (tester) async {
      await pumpChat(tester);
      await tester.tap(find.text('Not now').last);
      await settle(tester);

      expect(find.text('Prefers morning runs'), findsNothing);
      expect(find.text('REMEMBER THIS?'), findsOneWidget);
      // Nothing was stored (the provider was never even created).
      expect(find.text('Aurora will remember that'), findsNothing);
    });

    testWidgets('a reply without proposals renders no chips', (tester) async {
      await pumpPhone(tester, const AuroraChatScreen(), overrides: [
        auroraUsageProvider.overrideWithValue(null),
        onlineProvider.overrideWith((ref) => Stream.value(true)),
        auroraChatProvider.overrideWith(() => _FixedChat()),
      ]);
      await settle(tester);
      expect(find.text('REMEMBER THIS?'), findsNothing);
    });
  });

  // ─── Conversation history ───

  group('conversation history', () {
    late _HistoryChat chat;

    Future<void> pumpHistory(WidgetTester tester) async {
      chat = _HistoryChat();
      await pumpPhone(tester, _sheet(ConversationHistorySheet(now: _now)), overrides: [
        auroraChatProvider.overrideWith(() => chat),
        auroraConversationsProvider.overrideWith((ref) => Stream.value(_conversations)),
      ]);
      await settle(tester);
    }

    testWidgets('lists conversations with relative dates', (tester) async {
      await pumpHistory(tester);
      expect(find.text('Plan my week'), findsOneWidget);
      expect(find.text('Today, 9:15 am'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('2 Sep'), findsOneWidget);
      expect(find.text('Open now'), findsOneWidget);
    });

    testWidgets('tapping one opens it', (tester) async {
      await pumpHistory(tester);
      await tester.tap(find.text('I feel stuck'));
      await settle(tester);
      expect(chat.opened, ['c2']);
    });

    testWidgets('long press deletes with undo', (tester) async {
      await pumpHistory(tester);
      await tester.longPress(find.text('Celebrate a small win'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester, const Duration(milliseconds: 600));
      expect(chat.deleted, ['c3']);
      expect(find.text('Conversation deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await settle(tester, const Duration(seconds: 5));
      expect(chat.restored, ['c3']);
    });

    test('date labels', () {
      final now = DateTime(2026, 10, 28, 18);
      expect(conversationDateLabel(DateTime(2026, 10, 25, 8), now), 'Sunday');
      expect(conversationDateLabel(DateTime(2025, 12, 31), now), '31 Dec 2025');
    });
  });

  // ─── Plan my day ───

  group('plan my day sheet', () {
    Future<void> pumpPlan(WidgetTester tester, AuroraDayPlan plan) async {
      await pumpPhone(tester, _sheet(const PlanDaySheet()), overrides: [
        planDayProvider.overrideWith(
            () => _FixedPlan(PlanDayState(energy: AuroraEnergy.low, plan: plan))),
        habitsStreamProvider.overrideWith((ref) => Stream.value(sampleHabits)),
        tasksStreamProvider.overrideWith((ref) => Stream.value(sampleTasks)),
      ]);
      await settle(tester);
    }

    testWidgets('renders picks resolved locally and skips unknown ids', (tester) async {
      await pumpPlan(
        tester,
        const AuroraDayPlan(
          message: 'A gentle day. Two small things are enough.',
          picks: [
            AuroraPlanPick(kind: 'habit', id: 'h4', reason: 'Ten minutes is enough today.'),
            AuroraPlanPick(kind: 'habit', id: 'ghost', reason: 'Not on this device.'),
            AuroraPlanPick(kind: 'task', id: 't2'),
          ],
          later: ['t3', 'nope'],
        ),
      );

      expect(find.text('A gentle day. Two small things are enough.'), findsOneWidget);
      expect(find.text('Wind down before bed'), findsOneWidget);
      expect(find.text('Ten minutes is enough today.'), findsOneWidget);
      expect(find.text('Read 20 pages'), findsOneWidget);
      expect(find.text('Not on this device.'), findsNothing);
      expect(find.byType(CheckCircle), findsNWidgets(2));
      expect(find.text('Set aside for today'), findsOneWidget);
      expect(find.text('Plan the week'), findsOneWidget);
    });

    testWidgets('handles a plan with no picks', (tester) async {
      await pumpPlan(
        tester,
        const AuroraDayPlan(message: 'Rest is the plan today.', picks: [], later: []),
      );
      expect(find.text('Rest is the plan today.'), findsOneWidget);
      expect(find.text('No picks today. A lighter day counts too.'), findsOneWidget);
      expect(find.byType(CheckCircle), findsNothing);
      expect(find.text('Set aside for today'), findsNothing);
    });

    testWidgets('starts on the energy picker', (tester) async {
      await pumpPhone(tester, _sheet(const PlanDaySheet()), overrides: [
        planDayProvider.overrideWith(() => _FixedPlan(const PlanDayState())),
      ]);
      await settle(tester);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Steady'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Plan my day'), findsNWidgets(2));
    });
  });

  // ─── Break a goal down ───

  group('goal steps sheet', () {
    testWidgets('untick a step, add the rest, see the success state', (tester) async {
      final steps = _FixedSteps();
      await pumpPhone(tester, _sheet(GoalStepsSheet(goal: sampleGoals.first)), overrides: [
        goalStepsProvider.overrideWith(() => steps),
      ]);
      await settle(tester);

      expect(find.text('Three small steps to start.'), findsOneWidget);
      expect(find.text('Add 3 steps'), findsOneWidget);

      await tester.tap(find.text('Buy proper running shoes'));
      await settle(tester, const Duration(milliseconds: 500));
      expect(find.text('Add 2 steps'), findsOneWidget);

      await tester.tap(find.text('Add 2 steps'));
      await settle(tester);

      expect(steps.added.single.map((s) => s.title),
          ['Run 3k without stopping', 'Stretch after every run']);
      expect(find.text('Added 2 steps to Grow.'), findsOneWidget);
    });
  });
}

class _FixedChat extends AuroraChatNotifier {
  @override
  AuroraChatState build() => const AuroraChatState(messages: [
        ChatMessage(role: ChatRole.user, content: 'Hello'),
        ChatMessage(role: ChatRole.aurora, content: 'Hi there.'),
      ]);
}
