import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/world_dao.dart';
import 'package:atlas_flutter_app/features/world/providers/world_providers.dart';

void main() {
  late AtlasDatabase db;
  late WorldDao dao;

  setUp(() {
    db = AtlasDatabase.forTesting(NativeDatabase.memory());
    dao = WorldDao(db);
  });

  tearDown(() => db.close());

  test('a world merged with the server\'s 8x8 sign-up map is repaired to 30 places', () async {
    final t0 = DateTime(2026, 10, 1);
    // What sync left behind: the server's 64 named places, cheap and mostly
    // unlocked.
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        await dao.insertTile(WorldTilesCompanion(
          id: Value('s-$x-$y'),
          userId: const Value('u1'),
          name: const Value('Iron Peak'),
          tileType: const Value('mountain'),
          isUnlocked: Value(x + y < 6),
          unlockRequirement: Value((x + y) * 50),
          positionX: Value(x),
          positionY: Value(y),
          createdAt: Value(t0),
          updatedAt: Value(t0),
        ));
      }
    }

    // ...and a badge it handed out: 30 "places" unlocked on that map.
    Future<void> badge(String title) => db.into(db.achievements).insert(AchievementsCompanion(
          id: Value(title),
          userId: const Value('u1'),
          title: Value(title),
          achievementType: const Value('milestone'),
          isUnlocked: const Value(true),
          progress: const Value(1.0),
          unlockedAt: Value(t0),
          createdAt: Value(t0),
          updatedAt: Value(t0),
        ));
    await badge('World Builder');
    await badge('First Light');

    await WorldActions(dao).ensureSeeded('u1');

    final badges = {for (final a in await db.select(db.achievements).get()) a.title: a};
    expect(badges['World Builder']!.isUnlocked, isFalse);
    expect(badges['World Builder']!.isDirty, isTrue);
    expect(badges['First Light']!.isUnlocked, isTrue, reason: 'other badges are untouched');

    final live = await dao.getAllTiles('u1');
    expect(live, hasLength(kWorldSize));
    expect(live.every((t) => isWorldPlace(t.positionX, t.positionY)), isTrue);
    // Every place is now the one the app would have made, and only the
    // origin is open: discovery re-opens what the XP reaches.
    for (final t in live) {
      final i = t.positionY * kWorldCols + t.positionX;
      expect(t.unlockRequirement, WorldActions.costFor(i));
      expect(t.isUnlocked, i == 0);
      expect(t.name, isNot('Iron Peak'));
      expect(t.isDirty, isTrue);
    }
    // The strays are tombstoned, so sync removes them from the server too.
    final strays = await (db.select(db.worldTiles)..where((w) => w.isDeleted.equals(true))).get();
    expect(strays, hasLength(64 - kWorldSize));
    expect(strays.every((t) => t.isDirty), isTrue);
  });

  test('a healthy world is left alone', () async {
    final actions = WorldActions(dao);
    await actions.ensureSeeded('u1');
    final before = await dao.getAllTiles('u1');
    await WorldActions(dao).ensureSeeded('u1');
    final after = await dao.getAllTiles('u1');
    expect(after.map((t) => (t.id, t.updatedAt, t.unlockRequirement)),
        before.map((t) => (t.id, t.updatedAt, t.unlockRequirement)));
  });

  test('isWorldPlace covers exactly the 5-wide, 30-place grid', () {
    expect(isWorldPlace(0, 0), isTrue);
    expect(isWorldPlace(4, 5), isTrue);
    expect(isWorldPlace(5, 0), isFalse);
    expect(isWorldPlace(0, 6), isFalse);
    expect(isWorldPlace(-1, 0), isFalse);
  });
}
