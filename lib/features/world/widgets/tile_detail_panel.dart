import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/world_tile.dart';
import 'package:atlas_flutter_app/features/world/providers/world_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';

/// Shows a modal bottom sheet with tile details.
void showTileDetailPanel(BuildContext context, WorldTile tile) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _TileDetailPanel(tile: tile),
  );
}

class _TileDetailPanel extends ConsumerWidget {
  final WorldTile tile;

  const _TileDetailPanel({required this.tile});

  IconData _tileIcon(WorldTileType type) => switch (type) {
        WorldTileType.forest => Icons.park_rounded,
        WorldTileType.mountain => Icons.terrain_rounded,
        WorldTileType.ocean => Icons.water_rounded,
        WorldTileType.desert => Icons.wb_sunny_rounded,
        WorldTileType.city => Icons.location_city_rounded,
        WorldTileType.village => Icons.house_rounded,
        WorldTileType.castle => Icons.castle_rounded,
        WorldTileType.ruins => Icons.account_balance_rounded,
        WorldTileType.special => Icons.auto_awesome_rounded,
      };

  Color _tileColor(WorldTileType type) => switch (type) {
        WorldTileType.forest => AppColors.xpPrimary,
        WorldTileType.mountain => AppColors.textSecondaryLight,
        WorldTileType.ocean => AppColors.info,
        WorldTileType.desert => AppColors.tertiary,
        WorldTileType.city => AppColors.categoryWork,
        WorldTileType.village => AppColors.categoryFitness,
        WorldTileType.castle => AppColors.badgeEpic,
        WorldTileType.ruins => AppColors.badgeBronze,
        WorldTileType.special => AppColors.badgeLegendary,
      };

  String _tileTypeName(WorldTileType type) =>
      '${type.name[0].toUpperCase()}${type.name.substring(1)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _tileColor(tile.tileType);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Tile icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_tileIcon(tile.tileType), size: 36, color: color),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            tile.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _tileTypeName(tile.tileType),
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          if (tile.description != null && tile.description!.isNotEmpty)
            Text(
              tile.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),

          if (tile.isUnlocked) ...[
            // Unlocked details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_open_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlocked',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                        if (tile.unlockedAt != null)
                          Text(
                            DateFormat('MMMM d, y').format(tile.unlockedAt!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Locked details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Requires ${tile.unlockRequirement} XP',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: 0.3, // Placeholder — user XP / requirement
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Unlock Tile',
              icon: Icons.lock_open_rounded,
              onPressed: () {
                ref.read(worldProvider.notifier).unlockTile(tile.id);
                Navigator.of(context).pop();
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
