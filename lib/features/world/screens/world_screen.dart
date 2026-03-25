import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/world_tile.dart';
import 'package:atlas_flutter_app/features/world/providers/world_provider.dart';
import 'package:atlas_flutter_app/features/world/widgets/tile_detail_panel.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_card.dart';
import 'package:atlas_flutter_app/shared/widgets/app_error_widget.dart';
import 'package:atlas_flutter_app/shared/widgets/loading_shimmer.dart';

class WorldScreen extends ConsumerWidget {
  const WorldScreen({super.key});

  Color _tileColor(WorldTileType type, bool isUnlocked, bool isDark) {
    if (!isUnlocked) {
      return isDark
          ? AppColors.cardBorderDark.withValues(alpha: 0.6)
          : AppColors.cardBorderLight;
    }
    return switch (type) {
      WorldTileType.grass => AppColors.success,
      WorldTileType.forest => AppColors.xpPrimary,
      WorldTileType.mountain => const Color(0xFF78909C),
      WorldTileType.water => AppColors.info,
      WorldTileType.desert => AppColors.tertiary,
      WorldTileType.city => AppColors.categoryWork,
      WorldTileType.building => AppColors.categoryFitness,
      WorldTileType.special => AppColors.badgeLegendary,
    };
  }

  IconData _tileIcon(WorldTileType type) => switch (type) {
        WorldTileType.grass => Icons.grass_rounded,
        WorldTileType.forest => Icons.park_rounded,
        WorldTileType.mountain => Icons.terrain_rounded,
        WorldTileType.water => Icons.water_rounded,
        WorldTileType.desert => Icons.wb_sunny_rounded,
        WorldTileType.city => Icons.location_city_rounded,
        WorldTileType.building => Icons.house_rounded,
        WorldTileType.special => Icons.auto_awesome_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final worldState = ref.watch(worldProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'World Map',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: worldState.isLoading
          ? Center(child: LoadingShimmer.card(height: 300))
          : worldState.error != null
              ? AppErrorDisplay(
                  message: worldState.error!,
                  onRetry: () =>
                      ref.read(worldProvider.notifier).loadWorld(),
                )
              : worldState.tiles.isEmpty
                  ? _buildEmptyState(context, ref)
                  : Column(
                      children: [
                        // Stats bar
                        _buildStatsBar(context, worldState, isDark),
                        const SizedBox(height: 4),

                        // Instruction text
                        _buildInstructions(context, worldState),
                        const SizedBox(height: 4),

                        // World grid
                        Expanded(
                          child: _buildWorldGrid(
                            context,
                            ref,
                            worldState,
                            isDark,
                          ),
                        ),

                        // Legend
                        _buildLegend(context, isDark),
                      ],
                    ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Generating your world...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context, WorldState worldState) {
    final theme = Theme.of(context);
    // Check if only the origin tile is unlocked
    final unlockedCount = worldState.unlockedCount;
    final String message;
    if (unlockedCount <= 1) {
      message = 'Tap the glowing tile to start your adventure!';
    } else {
      message = 'Earn XP to unlock new tiles! Tap a tile to see details and unlock it.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatsBar(
    BuildContext context,
    WorldState worldState,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final unlocked = worldState.unlockedCount;
    final total = worldState.totalCount > 0 ? worldState.totalCount : 64;
    final progress = unlocked / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.xpPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    color: AppColors.xpPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unlocked / $total tiles unlocked',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor:
                              AppColors.xpPrimary.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.xpPrimary),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorldGrid(
    BuildContext context,
    WidgetRef ref,
    WorldState worldState,
    bool isDark,
  ) {
    // Build an 8x8 grid. Map tiles to positions or fill with placeholders.
    final tileMap = <String, WorldTile>{};
    for (final tile in worldState.tiles) {
      tileMap['${tile.positionX},${tile.positionY}'] = tile;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        boundaryMargin: const EdgeInsets.all(40),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.count(
              crossAxisCount: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              children: List.generate(64, (index) {
                final x = index % 8;
                final y = index ~/ 8;
                final tile = tileMap['$x,$y'];

                if (tile != null) {
                  return _WorldTileWidget(
                    tile: tile,
                    color: _tileColor(tile.tileType, tile.isUnlocked, isDark),
                    icon: _tileIcon(tile.tileType),
                    isSelected: worldState.selectedTile?.id == tile.id,
                    onTap: () {
                      ref.read(worldProvider.notifier).selectTile(tile);
                      showTileDetailPanel(context, tile);
                    },
                  );
                }

                // Empty/placeholder tile
                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark.withValues(alpha: 0.4)
                        : AppColors.cardBorderLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final types = [
      (WorldTileType.forest, 'Forest'),
      (WorldTileType.mountain, 'Mountain'),
      (WorldTileType.water, 'Water'),
      (WorldTileType.city, 'City'),
      (WorldTileType.special, 'Special'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: types.map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _tileColor(entry.$1, true, isDark),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                entry.$2,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _WorldTileWidget extends StatelessWidget {
  final WorldTile tile;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _WorldTileWidget({
    required this.tile,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: tile.isUnlocked
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: tile.isUnlocked
              ? Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85))
              : Icon(
                  Icons.lock_rounded,
                  size: 12,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
        ),
      ),
    );
  }
}
