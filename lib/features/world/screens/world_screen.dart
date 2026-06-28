import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/sample/sample_world.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/living_horizon.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// The "Your World" tab — a living map that flourishes tile by tile as the
/// user tends their habits. Tab root, so it carries no back button.
class WorldScreen extends ConsumerWidget {
  const WorldScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = ref.watch(worldProvider);
    final unlockedCount = tiles.where((t) => t.unlocked).length;
    final total = tiles.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            AtlasHeader(
              title: 'Your World',
              subtitle: 'Tend yourself, watch it grow',
              trailing: CircleActionButton(
                icon: Icons.emoji_events_outlined,
                onTap: () => context.push('/world/achievements'),
              ),
            ),
            AppSpacing.gapLg,
            _HeroBanner(unlockedCount: unlockedCount, total: total),
            AppSpacing.gapLg,
            _WorldGrid(tiles: tiles),
            AppSpacing.gapXl,
            const SectionHeader(title: 'Legend'),
            const _Legend(),
          ],
        ),
      ),
    );
  }
}

/// A living horizon hero with an overlaid "alive" count.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.unlockedCount, required this.total});

  final int unlockedCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : unlockedCount / total;

    return Stack(
      children: [
        LivingHorizon(
          height: 150,
          progress: progress,
          borderRadius:
              const BorderRadius.all(Radius.circular(AppSpacing.radiusLg)),
        ),
        Positioned(
          left: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs + 2,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco_rounded,
                    size: 15, color: AppColors.auroraTeal),
                AppSpacing.hGapXs,
                Text(
                  '$unlockedCount / $total tiles alive',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppMotion.medium).slideY(
          begin: 0.06,
          end: 0,
          duration: AppMotion.medium,
          curve: AppMotion.standard,
        );
  }
}

class _WorldGrid extends ConsumerWidget {
  const _WorldGrid({required this.tiles});

  final List<WorldTileInfo> tiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
      ),
      itemBuilder: (context, index) => _WorldTile(
        tile: tiles[index],
        onTap: () => _onTap(context, ref, index, tiles[index]),
      ),
    );
  }

  void _onTap(
    BuildContext context,
    WidgetRef ref,
    int index,
    WorldTileInfo tile,
  ) {
    if (tile.glowing) {
      ref.read(worldProvider.notifier).unlock(index);
      return;
    }
    _showTileSheet(context, tile);
  }
}

class _WorldTile extends StatelessWidget {
  const _WorldTile({required this.tile, required this.onTap});

  final WorldTileInfo tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tile.type.color;

    late final Color bg;
    late final Widget icon;
    Border? border;
    List<BoxShadow>? shadow;

    if (tile.unlocked) {
      bg = color.withValues(alpha: 0.18);
      icon = Icon(tile.type.icon, color: color, size: 22);
    } else if (tile.glowing) {
      bg = color.withValues(alpha: 0.22);
      icon = Icon(tile.type.icon, color: color, size: 22);
      border = Border.all(color: AppColors.auroraLilac, width: 1.5);
      shadow = [
        BoxShadow(
          color: AppColors.auroraLilac.withValues(alpha: 0.45),
          blurRadius: 16,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: AppColors.auroraTeal.withValues(alpha: 0.30),
          blurRadius: 22,
          spreadRadius: 1,
        ),
      ];
    } else {
      bg = theme.colorScheme.surfaceContainerHighest;
      icon = Icon(
        Icons.lock_outline,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        size: 18,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: border,
          boxShadow: shadow,
        ),
        child: Center(child: icon),
      ),
    );
  }
}

void _showTileSheet(BuildContext context, WorldTileInfo tile) {
  final theme = Theme.of(context);
  final color = tile.type.color;
  final unlocked = tile.unlocked;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: unlocked
                      ? color.withValues(alpha: 0.18)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  unlocked ? tile.type.icon : Icons.lock_outline,
                  color: unlocked ? color : theme.colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.type.label,
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      unlocked ? 'Flourishing' : 'Dormant',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Text(
            unlocked
                ? 'A peaceful ${tile.type.label.toLowerCase()}, earned by '
                    'tending your habits. Keep going and your world grows '
                    'richer.'
                : 'This ${tile.type.label.toLowerCase()} is still dormant. '
                    'It needs ${tile.cost} XP to bloom — tend your habits to '
                    'bring it to life.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (!unlocked) ...[
            AppSpacing.gapMd,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 18, color: AppColors.tertiary),
                  AppSpacing.hGapSm,
                  Text(
                    '${tile.cost} XP to bloom',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          for (final type in TileType.values)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(type.icon, color: type.color, size: 15),
                ),
                AppSpacing.hGapXs,
                Text(
                  type.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
