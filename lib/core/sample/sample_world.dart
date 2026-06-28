import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// Dummy data for the World map and Achievements.
/// TODO(backend): replace with real procedural world + achievements.

enum TileType { grass, forest, mountain, water, desert, city, building, special }

extension TileVisuals on TileType {
  Color get color => switch (this) {
        TileType.grass => AppColors.success,
        TileType.forest => AppColors.secondary,
        TileType.mountain => AppColors.badgeCommon,
        TileType.water => AppColors.info,
        TileType.desert => AppColors.tertiary,
        TileType.city => AppColors.categoryWork,
        TileType.building => AppColors.categoryFitness,
        TileType.special => AppColors.badgeLegendary,
      };

  IconData get icon => switch (this) {
        TileType.grass => Icons.grass_rounded,
        TileType.forest => Icons.park_rounded,
        TileType.mountain => Icons.terrain_rounded,
        TileType.water => Icons.water_rounded,
        TileType.desert => Icons.wb_sunny_rounded,
        TileType.city => Icons.location_city_rounded,
        TileType.building => Icons.cottage_rounded,
        TileType.special => Icons.auto_awesome_rounded,
      };

  String get label => switch (this) {
        TileType.grass => 'Meadow',
        TileType.forest => 'Forest',
        TileType.mountain => 'Mountain',
        TileType.water => 'Lake',
        TileType.desert => 'Dunes',
        TileType.city => 'Town',
        TileType.building => 'Cottage',
        TileType.special => 'Wonder',
      };
}

class WorldTileInfo {
  const WorldTileInfo({
    required this.type,
    required this.unlocked,
    this.glowing = false,
    this.cost = 0,
  });

  final TileType type;
  final bool unlocked;
  final bool glowing; // next tile to unlock
  final int cost; // XP to unlock (if locked)

  WorldTileInfo copyWith({bool? unlocked, bool? glowing}) => WorldTileInfo(
        type: type,
        unlocked: unlocked ?? this.unlocked,
        glowing: glowing ?? this.glowing,
        cost: cost,
      );
}

class WorldNotifier extends Notifier<List<WorldTileInfo>> {
  static const _types = TileType.values;

  @override
  List<WorldTileInfo> build() {
    // 5 columns x 6 rows. First ~14 unlocked, one glowing, rest locked.
    const unlockedCount = 14;
    const glowingIndex = 14;
    return List.generate(30, (i) {
      final type = _types[i % _types.length];
      return WorldTileInfo(
        type: type,
        unlocked: i < unlockedCount,
        glowing: i == glowingIndex,
        cost: 50 + ((i - unlockedCount).clamp(0, 99)) * 25,
      );
    });
  }

  int get unlockedCount => state.where((t) => t.unlocked).length;

  void unlock(int index) {
    if (index < 0 || index >= state.length) return;
    final next = [...state];
    next[index] = next[index].copyWith(unlocked: true, glowing: false);
    // Light up the following tile.
    if (index + 1 < next.length && !next[index + 1].unlocked) {
      next[index + 1] = next[index + 1].copyWith(glowing: true);
    }
    state = next;
  }
}

final worldProvider =
    NotifierProvider<WorldNotifier, List<WorldTileInfo>>(WorldNotifier.new);

// ─── Achievements ───────────────────────────────────────────────────

enum Tier { bronze, common, rare, epic, legendary }

extension TierVisuals on Tier {
  Color get color => switch (this) {
        Tier.bronze => AppColors.badgeBronze,
        Tier.common => AppColors.badgeCommon,
        Tier.rare => AppColors.badgeRare,
        Tier.epic => AppColors.badgeEpic,
        Tier.legendary => AppColors.badgeLegendary,
      };

  String get label => switch (this) {
        Tier.bronze => 'Bronze',
        Tier.common => 'Common',
        Tier.rare => 'Rare',
        Tier.epic => 'Epic',
        Tier.legendary => 'Legendary',
      };
}

class SampleAchievement {
  const SampleAchievement({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.tier,
    required this.unlocked,
    this.progress = 1,
  });

  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Tier tier;
  final bool unlocked;
  final double progress; // 0..1 for locked, in-progress ones
}

final achievementsProvider = Provider<List<SampleAchievement>>((ref) => const [
      SampleAchievement(
          id: 'a1',
          title: 'First Light',
          desc: 'Complete your first ritual',
          icon: Icons.wb_twilight_rounded,
          tier: Tier.bronze,
          unlocked: true),
      SampleAchievement(
          id: 'a2',
          title: 'Tended Ten',
          desc: 'Finish 10 tasks',
          icon: Icons.task_alt_rounded,
          tier: Tier.common,
          unlocked: true),
      SampleAchievement(
          id: 'a3',
          title: 'Week of Calm',
          desc: 'A 7-day meditation streak',
          icon: Icons.self_improvement_rounded,
          tier: Tier.rare,
          unlocked: true),
      SampleAchievement(
          id: 'a4',
          title: 'World Builder',
          desc: 'Unlock 15 tiles',
          icon: Icons.public_rounded,
          tier: Tier.epic,
          unlocked: false,
          progress: 0.93),
      SampleAchievement(
          id: 'a5',
          title: 'Evergreen',
          desc: 'Keep a 30-day streak',
          icon: Icons.forest_rounded,
          tier: Tier.epic,
          unlocked: false,
          progress: 0.4),
      SampleAchievement(
          id: 'a6',
          title: 'Dawn to Dusk',
          desc: 'Reach level 10',
          icon: Icons.auto_awesome_rounded,
          tier: Tier.legendary,
          unlocked: false,
          progress: 0.7),
      SampleAchievement(
          id: 'a7',
          title: 'Hydrated',
          desc: 'Drink water 50 times',
          icon: Icons.water_drop_rounded,
          tier: Tier.common,
          unlocked: true),
      SampleAchievement(
          id: 'a8',
          title: 'Bookworm',
          desc: 'Read 5 books',
          icon: Icons.menu_book_rounded,
          tier: Tier.rare,
          unlocked: false,
          progress: 0.6),
    ]);
