import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/aurora_conversation_dao.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_conversation_repository.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';

void main() {
  late AtlasDatabase db;
  late AuroraConversationRepository repo;
  var now = DateTime(2026, 10, 28, 9);

  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    now = DateTime(2026, 10, 28, 9);
    repo = AuroraConversationRepository(AuroraConversationDao(db),
        clock: () => now);
  });

  tearDown(() => db.close());

  test('create titles the conversation from the first message (60 chars)',
      () async {
    final c = await repo.create('u1', firstMessage: '  ${'word ' * 30}');
    expect(c.title.length, lessThanOrEqualTo(60));
    expect(c.title, startsWith('word word'));
    final short = await repo.create('u1', firstMessage: 'Plan tomorrow');
    expect(short.title, 'Plan tomorrow');
  });

  test('append keeps order and the cards, and bumps updatedAt', () async {
    final c = await repo.create('u1', firstMessage: 'Hi');
    await repo.append(c.id, role: 'user', content: 'Hi');
    now = now.add(const Duration(minutes: 1));
    await repo.append(
      c.id,
      role: 'aurora',
      content: 'Hello you.',
      suggestions: const [
        AuroraSuggestion(title: 'Stretch', kind: 'habit', xp: 15, recommended: true),
      ],
      followUps: const ['Plan tomorrow'],
      created: const [AuroraCreatedEntity(type: 'task', title: 'Call mum', taskType: 'daily')],
    );
    // Same second as the previous one: insertion order still holds.
    await repo.append(c.id, role: 'user', content: 'Thanks');

    final msgs = await repo.messagesOf(c.id);
    expect(msgs.map((m) => m.content), ['Hi', 'Hello you.', 'Thanks']);
    final reply = msgs[1];
    expect(reply.role, 'aurora');
    final s = AuroraConversationRepository.suggestionsOf(reply).single;
    expect(s.title, 'Stretch');
    expect(s.recommended, isTrue);
    expect(AuroraConversationRepository.followUpsOf(reply), ['Plan tomorrow']);
    expect(AuroraConversationRepository.createdOf(reply).single.taskType, 'daily');

    final row = (await repo.getConversation(c.id))!;
    expect(row.updatedAt, now);
  });

  test('list is newest first, per user', () async {
    final a = await repo.create('u1', firstMessage: 'A');
    now = now.add(const Duration(minutes: 1));
    final b = await repo.create('u1', firstMessage: 'B');
    await repo.create('u2', firstMessage: 'Other user');
    now = now.add(const Duration(minutes: 1));
    await repo.append(a.id, role: 'user', content: 'again');

    expect((await repo.listConversations('u1')).map((c) => c.id), [a.id, b.id]);
    expect((await repo.watchConversations('u1').first).first.id, a.id);
  });

  test('openRecent restores the last one only within 12 hours', () async {
    expect(await repo.openRecent('u1'), isNull);
    final c = await repo.create('u1', firstMessage: 'Hi');
    now = now.add(const Duration(hours: 11, minutes: 59));
    expect((await repo.openRecent('u1'))?.id, c.id);
    now = now.add(const Duration(minutes: 2));
    expect(await repo.openRecent('u1'), isNull);
  });

  test('delete removes the messages; restore undoes it exactly', () async {
    final c = await repo.create('u1', firstMessage: 'Hi');
    await repo.append(c.id, role: 'user', content: 'Hi');
    await repo.append(c.id, role: 'aurora', content: 'Hello');

    final deleted = (await repo.delete(c.id))!;
    expect(await repo.listConversations('u1'), isEmpty);
    expect(await db.select(db.auroraMessages).get(), isEmpty);
    expect(deleted.messages, hasLength(2));

    await repo.restore(deleted);
    expect((await repo.listConversations('u1')).single.title, 'Hi');
    expect((await repo.messagesOf(c.id)).map((m) => m.content), ['Hi', 'Hello']);
    expect(await repo.delete('missing'), isNull);
  });

  test('the account wipe covers chat history', () async {
    final c = await repo.create('u1', firstMessage: 'Hi');
    await repo.append(c.id, role: 'user', content: 'Hi');
    await db.wipeAllLocalData();
    expect(await db.select(db.auroraConversations).get(), isEmpty);
    expect(await db.select(db.auroraMessages).get(), isEmpty);
  });
}
