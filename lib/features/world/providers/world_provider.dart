import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:atlas_flutter_app/data/models/world_tile.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/data/repositories/world_repository.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

// ─── World State ─────────────────────────────────────────────────

class WorldState {
  final List<WorldTile> tiles;
  final WorldTile? selectedTile;
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final String? error;

  const WorldState({
    this.tiles = const [],
    this.selectedTile,
    this.stats,
    this.isLoading = true,
    this.error,
  });

  WorldState copyWith({
    List<WorldTile>? tiles,
    WorldTile? selectedTile,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSelectedTile = false,
  }) {
    return WorldState(
      tiles: tiles ?? this.tiles,
      selectedTile:
          clearSelectedTile ? null : (selectedTile ?? this.selectedTile),
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get unlockedCount => tiles.where((t) => t.isUnlocked).length;
  int get totalCount => tiles.length;
}

// ─── World Notifier ──────────────────────────────────────────────

class WorldNotifier extends Notifier<WorldState> {
  late final WorldRepository _worldRepository;

  @override
  WorldState build() {
    _worldRepository = ref.read(worldRepositoryProvider);
    Future.microtask(() => loadWorld());
    return const WorldState();
  }

  Future<void> loadWorld() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _worldRepository.getWorldTiles(),
        _worldRepository.getWorldStats(),
      ], eagerError: false);

      var tiles = results[0] as List<WorldTile>;
      _log.i('[World] Loaded ${tiles.length} tiles');

      // Auto-seed if the world is empty
      if (tiles.isEmpty) {
        _log.i('[World] No tiles found, seeding world...');
        try {
          await _worldRepository.seedWorld();
          _log.i('[World] Seed complete, re-fetching tiles...');
          tiles = await _worldRepository.getWorldTiles();
          _log.i('[World] After seed: ${tiles.length} tiles');
        } catch (e) {
          _log.e('[World] Seed failed', error: e);
        }
      }

      state = state.copyWith(
        tiles: tiles,
        stats: results[1] as Map<String, dynamic>?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectTile(WorldTile? tile) {
    if (tile == null) {
      state = state.copyWith(clearSelectedTile: true);
    } else {
      state = state.copyWith(selectedTile: tile);
    }
  }

  Future<void> unlockTile(String id) async {
    try {
      await _worldRepository.unlockTile(id);
      final tiles = state.tiles
          .map((t) => t.id == id
              ? t.copyWith(isUnlocked: true, unlockedAt: DateTime.now())
              : t)
          .toList();
      state = state.copyWith(tiles: tiles);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final worldProvider = NotifierProvider<WorldNotifier, WorldState>(
  WorldNotifier.new,
);
