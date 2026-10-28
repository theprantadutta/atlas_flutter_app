import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';

void main() {
  test('chat result keeps memories_proposed, cleaned and capped', () {
    final r = AuroraChatResult.fromJson({
      'reply': 'Lovely.',
      'memories_proposed': [
        'Training for a 10k — in December',
        'x' * 201,
        42,
        '  Has a dog called Pip ',
        'has a DOG called pip',
        'One too many',
      ],
    });
    expect(r.memoriesProposed, hasLength(2));
    expect(r.memoriesProposed.first, isNot(contains('—')));
    expect(r.memoriesProposed.last, 'Has a dog called Pip');
    expect(AuroraChatResult.fromJson({'reply': 'x'}).memoriesProposed, isEmpty);
  });

  test('plan keeps only known ids, de-duplicates and caps picks at 4', () {
    final plan = AuroraDayPlan.fromJson({
      'message': 'A gentle day.',
      'picks': [
        {'kind': 'habit', 'id': 'h1', 'reason': 'Ten minutes is enough.'},
        {'kind': 'habit', 'id': 'invented', 'reason': 'Made up'},
        {'kind': 'task', 'id': 'h1', 'reason': 'Wrong kind'},
        {'kind': 'task', 'id': 't1'},
        {'kind': 'habit', 'id': 'h1'},
        {'kind': 'goal', 'id': 'g1'},
        {'kind': 'task', 'id': 't2'},
        {'kind': 'task', 'id': 't3'},
        {'kind': 'task', 'id': 't4'},
      ],
      'later': ['t4', 'nope', 't1'],
    }).onlyKnown(habitIds: {'h1'}, taskIds: {'t1', 't2', 't3', 't4'});
    expect(plan.picks.map((p) => p.id), ['h1', 't1', 't2', 't3']);
    expect(plan.later, ['t4']);
    expect(plan.picks.first.reason, 'Ten minutes is enough.');
  });

  test('an empty plan is fine', () {
    final plan = AuroraDayPlan.fromJson({'message': 'Rest today.'})
        .onlyKnown(habitIds: const {}, taskIds: const {});
    expect(plan.picks, isEmpty);
    expect(plan.message, 'Rest today.');
  });

  test('goal steps: types normalised, bad ones dropped, capped at 5', () {
    final res = AuroraGoalSteps.fromJson({
      'message': 'Small steps.',
      'steps': [
        {'title': 'Run 3k without stopping', 'type': 'weekly', 'category': 'health'},
        {'title': 'Sign up for a race', 'type': 'longTerm'},
        {'title': '', 'type': 'daily'},
        {'title': 'x' * 81, 'type': 'daily'},
        {'title': 'Stretch', 'type': 'whenever'},
        {'title': 'A', 'type': 'daily'},
        {'title': 'B', 'type': 'daily'},
        {'title': 'C', 'type': 'daily'},
      ],
    }, fallbackCategory: 'health');
    expect(res.steps, hasLength(5));
    expect(res.steps.map((s) => s.type).take(3), ['weekly', 'longTerm', 'daily']);
    expect(res.steps[1].category, 'health');
    final spec = res.steps.first.toCreation();
    expect(spec.type, 'task');
    expect(spec.taskType, 'weekly');
  });

  test('check-in reply and reflection period', () {
    final r = AuroraCheckInReply.fromJson(
        {'reply': 'Good to hear.', 'is_premium': false, 'free_replies_left': 2});
    expect(r.freeRepliesLeft, 2);
    expect(AuroraCheckInReply.fromJson({'reply': 'x', 'is_premium': true}).freeRepliesLeft,
        isNull);
    final letter = AuroraReflectionData.fromJson({
      'id': 'r',
      'content': 'Dear you',
      'period_start': '2026-09-28T00:00:00Z',
      'period_end': '2026-10-28T00:00:00Z',
      'created_at': '2026-10-28T00:00:00Z',
      'period': 'month',
    });
    expect(letter.period, 'month');
  });

  test('suggestions and created entities round trip through JSON', () {
    const s = AuroraSuggestion(
        title: 'Stretch', kind: 'habit', category: 'mindfulness', time: '22:15', xp: 15);
    final back = AuroraSuggestion.fromJson(s.toJson())!;
    expect(back.time, '22:15');
    expect(back.xp, 15);
    const c = AuroraCreatedEntity(type: 'task', title: 'Call', taskType: 'weekly', difficulty: 2);
    final c2 = AuroraCreatedEntity.fromJson(c.toJson());
    expect(c2.taskType, 'weekly');
    expect(c2.difficulty, 2);
  });
}
