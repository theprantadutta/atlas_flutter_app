import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/avatar_dao.dart';
import 'package:atlas_flutter_app/features/avatar/providers/avatar_providers.dart';

/// The avatar a device invents before it has pulled anything.
///
/// The server owns the avatar — it creates the 1:1 row at registration — so
/// this local row is only ever a stand-in. It used to be written dirty and
/// stamped `now`, which made it both destructive and permanent: the sync engine
/// pushed the invented 10/10/10 row over the real one, and last-write-wins then
/// rejected the server's genuinely older avatar on the way back down. A real
/// user reinstalling Atlas silently reset their avatar.
void main() {
  late AtlasDatabase db;
  late AvatarDao dao;
  late AvatarActions actions;

  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    dao = AvatarDao(db);
    actions = AvatarActions(dao);
  });

  tearDown(() => db.close());

  test('the placeholder is not pushed to the server', () async {
    await actions.ensureExists('user-1');

    // Dirty is what OfflineManager._pushAvatar selects on. A stand-in the user
    // never asked for must not be able to overwrite their real avatar.
    expect(await dao.getDirtyAvatars('user-1'), isEmpty);
  });

  test('the placeholder loses last-write-wins to any real avatar', () async {
    await actions.ensureExists('user-1');
    final placeholder = await dao.getAvatarByUserId('user-1');

    // A server avatar that has not been touched in a year still has to win,
    // because the placeholder carries no information at all.
    final realAvatarUpdatedAt =
        DateTime.now().subtract(const Duration(days: 365));
    expect(realAvatarUpdatedAt.isAfter(placeholder!.updatedAt), isTrue,
        reason: 'placeholder must be older than anything the server can hold');
  });

  test('it is only created when the user has no avatar', () async {
    await dao.upsertAvatar(AvatarsCompanion.insert(
      id: 'real-avatar',
      userId: 'user-1',
      name: 'Pranta',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      strength: const Value(62),
      wisdom: const Value(74),
      intelligence: const Value(58),
    ));

    await actions.ensureExists('user-1');

    final avatar = await dao.getAvatarByUserId('user-1');
    expect(avatar!.id, 'real-avatar');
    expect(avatar.strength, 62, reason: 'a real avatar must not be replaced');
  });

  test('a real edit still marks the row dirty', () async {
    await actions.ensureExists('user-1');
    await actions.saveAppearance('user-1', skin: 2, hair: 1, outfit: 3);

    // The fix must not stop genuine changes syncing.
    expect(await dao.getDirtyAvatars('user-1'), isNotEmpty);
  });
}
