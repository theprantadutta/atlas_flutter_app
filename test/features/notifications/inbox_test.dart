import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/notification_dao.dart';
import 'package:atlas_flutter_app/features/notifications/data/inbox.dart';

void main() {
  late AtlasDatabase db;
  late NotificationDao dao;
  late Inbox inbox;

  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    dao = NotificationDao(db);
    inbox = Inbox(dao);
  });
  tearDown(() => db.close());

  Future<void> earn() => inbox.add(
        userId: 'u1',
        kind: InboxKind.achievement,
        key: 'achievement:Tended Ten',
        title: 'You earned Tended Ten',
        body: 'Ten small things tended.',
      );

  test('the same moment is filed once, however often it is reported', () async {
    await earn();
    await earn();
    final rows = await dao.watchNotifications('u1').first;
    expect(rows, hasLength(1));
    expect(rows.single.type, InboxKind.achievement);
    expect(rows.single.isDirty, isFalse, reason: 'the inbox is never synced');
  });

  test('reading or dismissing it sticks when it is reported again', () async {
    await earn();
    final id = Inbox.idFor('u1', 'achievement:Tended Ten');
    await dao.markAsRead(id);
    await earn();
    expect((await dao.watchNotifications('u1').first).single.isRead, isTrue);

    await dao.softDeleteNotification(id, DateTime.now());
    await earn();
    expect(await dao.watchNotifications('u1').first, isEmpty);
  });

  test('every kind leads somewhere real', () {
    for (final k in [InboxKind.achievement, InboxKind.place, InboxKind.level, InboxKind.letter, InboxKind.account]) {
      expect(routeForInboxKind(k), isNotNull, reason: k);
    }
  });
}
