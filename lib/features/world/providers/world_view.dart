import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/world/providers/world_providers.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// A world tile, shown as a place on the globe.
class Place {
  const Place({
    required this.tile,
    required this.name,
    required this.icon,
    required this.color,
    required this.lon,
    required this.lat,
  });

  final WorldTile tile;
  final String name;
  final IconData icon;
  final Color color;

  /// Degrees. Longitude 0..360, latitude -55..55.
  final double lon;
  final double lat;

  bool get discovered => tile.isUnlocked;
  String get id => tile.id;
}

/// Seed tiles carry generic names ("Meadow"); give each a unique, warm name
/// by type and position. UI layer only: the stored name never changes.
const _placeNames = {
  'grass': ['Sun Meadow', 'Clover Fields', 'Sun Fields', 'Honey Meadow'],
  'forest': ['Pine Ridge', 'Fern Hollow', 'Cedar Wood', 'Moss Glen'],
  'mountain': ['Ember Peak', 'Cloud Ridge', 'Quiet Summit', 'Slate Heights'],
  'water': ['Still Lake', 'Lantern Bay', 'Mirror Pond', 'Glass Cove'],
  'desert': ['Amber Dunes', 'Saffron Flats', 'Copper Sands', 'Dune Sea'],
  'city': ['Lantern Town', 'Harbor Square', 'Old Market', 'Bell Street'],
  'building': ['Hearth Cottage', 'Lamp House', 'Garden Studio', 'Tea House'],
  'special': ['The Wonder', 'Starfall', 'Aurora Gate', 'Moon Garden'],
};

const _genericNames = {
  'Meadow', 'Forest', 'Mountain', 'Lake', 'Water', 'Dunes', 'Town', 'Cottage', 'Wonder', 'Tile',
};

String placeName(WorldTile t) {
  if (!_genericNames.contains(t.name)) return t.name;
  final list = _placeNames[t.tileType] ?? const ['Somewhere new'];
  final index = (t.positionY * 5 + t.positionX) ~/ 8; // nth of this type in the grid
  return list[index % list.length];
}

IconData placeIcon(String type) => switch (type) {
      'grass' => Symbols.grass_rounded,
      'forest' => Symbols.forest_rounded,
      'mountain' => Symbols.landscape_rounded,
      'water' => Symbols.sailing_rounded,
      'desert' => Symbols.wb_sunny_rounded,
      'city' => Symbols.location_city_rounded,
      'building' => Symbols.cottage_rounded,
      _ => Symbols.auto_awesome_rounded,
    };

Color placeColor(String type) => switch (type) {
      'grass' => AppColors.leaf,
      'forest' => AppColors.pine,
      'mountain' => AppColors.violet,
      'water' => AppColors.sky,
      'desert' => AppColors.amber,
      'city' => AppColors.coral,
      'building' => AppColors.amber,
      _ => AppColors.rose,
    };

Place placeFor(WorldTile t) {
  // Deterministic globe coordinates from the grid position. Row 0 (the
  // first places you find) sits in the north, so early discoveries are on
  // the upper face of the globe where the eye lands first.
  final lon = ((t.positionX / 5) * 360 + t.positionY * 37) % 360;
  final lat = (55 - t.positionY * 22).clamp(-55, 55).toDouble();
  return Place(
    tile: t,
    name: placeName(t),
    icon: placeIcon(t.tileType),
    color: placeColor(t.tileType),
    lon: lon,
    lat: lat,
  );
}

class WorldView {
  const WorldView({
    required this.places,
    required this.next,
    required this.totalXp,
    required this.previousThreshold,
  });

  final List<Place> places;
  final Place? next;
  final int totalXp;

  /// The XP threshold of the most recent discovery (progress starts here).
  final int previousThreshold;

  List<Place> get discovered => places.where((p) => p.discovered).toList()
    ..sort((a, b) => (b.tile.unlockedAt ?? DateTime(0)).compareTo(a.tile.unlockedAt ?? DateTime(0)));
  int get aliveCount => places.where((p) => p.discovered).length;

  int get xpToGo => next == null ? 0 : math.max(0, next!.tile.unlockRequirement - totalXp);

  double get nextProgress {
    final n = next;
    if (n == null) return 1;
    final span = n.tile.unlockRequirement - previousThreshold;
    if (span <= 0) return 1;
    return ((totalXp - previousThreshold) / span).clamp(0.0, 1.0);
  }
}

final worldViewProvider = Provider.autoDispose<WorldView?>((ref) {
  final tiles = ref.watch(worldTilesStreamProvider).value;
  if (tiles == null) return null;
  final xp = ref.watch(playerStatsProvider).totalXp;
  final places = tiles.map(placeFor).toList();
  final locked = places.where((p) => !p.discovered).toList()
    ..sort((a, b) => a.tile.unlockRequirement.compareTo(b.tile.unlockRequirement));
  final unlockedReqs = places.where((p) => p.discovered).map((p) => p.tile.unlockRequirement);
  return WorldView(
    places: places,
    next: locked.isEmpty ? null : locked.first,
    totalXp: xp,
    previousThreshold: unlockedReqs.isEmpty ? 0 : unlockedReqs.reduce(math.max),
  );
});

// ─── Discovery ──────────────────────────────────────────────────────

const _celebratedKey = 'atlas.discovered.celebrated';

/// Places discovered but not yet celebrated on screen (ids, oldest first).
class PendingDiscoveries extends Notifier<List<String>> {
  Set<String> _celebrated = {};
  bool _loaded = false;

  @override
  List<String> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      _celebrated = {...(jsonDecode(prefs.getString(_celebratedKey) ?? '[]') as List).cast<String>()};
    } catch (_) {
      _celebrated = {};
    }
    _loaded = true;
    state = List.of(state); // wake up watchers waiting for the load
  }

  bool get loaded => _loaded;

  void add(Iterable<String> ids) {
    final fresh = ids.where((id) => !_celebrated.contains(id) && !state.contains(id));
    if (fresh.isNotEmpty) state = [...state, ...fresh];
  }

  /// Mark celebrated so it never replays.
  Future<void> celebrated(String id) async {
    _celebrated.add(id);
    state = state.where((s) => s != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_celebratedKey, jsonEncode(_celebrated.toList()));
  }

  /// Existing discoveries (from before this feature) shouldn't celebrate.
  Future<void> markAllCelebrated(Iterable<String> ids) async {
    _celebrated.addAll(ids);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_celebratedKey, jsonEncode(_celebrated.toList()));
  }
}

final pendingDiscoveriesProvider =
    NotifierProvider<PendingDiscoveries, List<String>>(PendingDiscoveries.new);

/// Watches XP and the world: whenever total XP reaches a locked place's
/// threshold, unlock it (local-first) and queue its celebration. Kept alive
/// by the shell so it runs after every XP change and on resume.
final worldDiscoveryProvider = Provider<void>((ref) {
  final view = ref.watch(worldViewProvider);
  final pending = ref.read(pendingDiscoveriesProvider.notifier);
  if (view == null || !pending.loaded) {
    // Re-run once prefs have loaded.
    ref.watch(pendingDiscoveriesProvider);
    return;
  }
  final due = view.places
      .where((p) => !p.discovered && p.tile.unlockRequirement <= view.totalXp)
      .toList()
    ..sort((a, b) => a.tile.unlockRequirement.compareTo(b.tile.unlockRequirement));
  if (due.isEmpty) return;
  final actions = ref.read(worldActionsProvider);
  Future(() async {
    for (final p in due) {
      await actions.unlock(p.id);
    }
    pending.add(due.map((p) => p.id));
  });
});
