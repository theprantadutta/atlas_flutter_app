import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/world_dao.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;

/// Reactive stream of the current user's world tiles from Drift (source of
/// truth). Ordered by grid position so the map renders consistently.
final worldTilesStreamProvider =
    StreamProvider.autoDispose<List<WorldTile>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final dao = ref.read(worldDaoProvider);
  // Seed a starter world once so a fresh offline DB has a map to tend.
  ref.read(worldActionsProvider).ensureSeeded(userId);
  return dao.watchTiles(userId);
});

final worldActionsProvider = Provider<WorldActions>((ref) {
  return WorldActions(ref.read(worldDaoProvider));
});

/// The tile kinds, cycled across the seeded grid. Names match the backend
/// WorldTileType enum (lower-cased on the wire).
const _tileTypes = [
  'grass',
  'forest',
  'mountain',
  'water',
  'desert',
  'city',
  'building',
  'special',
];

/// Local-first world mutations: every write lands in Drift first and is
/// marked dirty for later (premium) sync.
class WorldActions {
  WorldActions(this._dao);
  final WorldDao _dao;
  final _uuid = const Uuid();
  final _seeded = <String>{};

  /// Light a dormant tile to life — a satisfying local-first write.
  Future<void> unlock(String id) async {
    final now = DateTime.now();
    await _dao.updateFields(
      id,
      WorldTilesCompanion(
        isUnlocked: const Value(true),
        unlockedAt: Value(now),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }

  /// Total XP at which the place in grid slot [index] is discovered: a
  /// gentle curve, so early places come quickly and the last of 30 takes a
  /// few months of steady tending (about 13,000 XP).
  static int costFor(int index) =>
      index <= 0 ? 0 : ((60 * math.pow(index, 1.6)) / 10).round() * 10;

  /// Brings an existing world back to what [ensureSeeded] makes.
  ///
  /// * Places outside the grid are removed (tombstoned, so sync removes them
  ///   from the server too). They come from the server's old sign-up seeding,
  ///   an 8x8 map that sync merged into this one: 64 places instead of 30.
  /// * An in-grid place from that map (its kind or name isn't ours) is
  ///   rewritten as the place this app puts there, locked again unless it's
  ///   the origin. Its cost came from a different curve; discovery re-opens
  ///   whatever the user's XP already reaches.
  /// * The old linear costs (50 + 25 per slot) let a whole world unlock in a
  ///   week. Our own places still locked at the old value are re-costed;
  ///   anything a user unlocked is left alone.
  Future<void> _rebalance(String userId) async {
    final tiles = await _dao.getAllTiles(userId);
    final now = DateTime.now();
    var foreign = false;
    for (final t in tiles) {
      if (!isWorldPlace(t.positionX, t.positionY)) {
        await _dao.softDeleteTile(t.id, now);
        foreign = true;
        continue;
      }
      final i = t.positionY * kWorldCols + t.positionX;
      final type = _tileTypes[i % _tileTypes.length];
      if (t.tileType != type || t.name != _nameFor(type)) {
        foreign = true;
        final origin = i == 0;
        await _dao.updateFields(
          t.id,
          WorldTilesCompanion(
            tileType: Value(type),
            name: Value(_nameFor(type)),
            description: const Value(null),
            unlockRequirement: Value(costFor(i)),
            isUnlocked: Value(origin),
            unlockedAt: Value(origin ? (t.unlockedAt ?? now) : null),
            updatedAt: Value(now),
            isDirty: const Value(true),
          ),
        );
        continue;
      }
      if (t.isUnlocked) continue;
      final legacy = 50 + (i - 1).clamp(0, 99) * 25;
      if (i == 0 || t.unlockRequirement != legacy) continue;
      await _dao.updateFields(
        t.id,
        WorldTilesCompanion(
          unlockRequirement: Value(costFor(i)),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
    }
    if (foreign) await _dao.relockWorldBuilder(userId, now);
  }

  Future<void> ensureSeeded(String userId) async {
    if (_seeded.contains(userId)) return;
    _seeded.add(userId);
    if (await _dao.countForUser(userId) > 0) {
      await _rebalance(userId);
      return;
    }

    final now = DateTime.now();
    const cols = kWorldCols;
    const total = kWorldSize;
    // A fresh world starts with just the origin tile alive; the rest unlock
    // as the user makes real progress.
    const unlockedCount = 1;
    for (var i = 0; i < total; i++) {
      final type = _tileTypes[i % _tileTypes.length];
      final unlocked = i < unlockedCount;
      final cost = costFor(i);
      await _dao.insertTile(WorldTilesCompanion(
        id: Value(_uuid.v4()),
        userId: Value(userId),
        name: Value(_nameFor(type)),
        tileType: Value(type),
        isUnlocked: Value(unlocked),
        unlockRequirement: Value(unlocked ? 0 : cost),
        positionX: Value(i % cols),
        positionY: Value(i ~/ cols),
        unlockedAt: unlocked ? Value(now) : const Value(null),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ));
    }
  }

  String _nameFor(String type) => switch (type) {
        'grass' => 'Meadow',
        'forest' => 'Forest',
        'mountain' => 'Mountain',
        'water' => 'Lake',
        'desert' => 'Dunes',
        'city' => 'Town',
        'building' => 'Cottage',
        'special' => 'Wonder',
        _ => 'Tile',
      };
}
