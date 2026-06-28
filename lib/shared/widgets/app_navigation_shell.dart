import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/aurora_nav_bar.dart';

/// Calm four-tab shell with the custom Aurora navigation: Home · Grow · World · You.
/// The nav floats over the body so content scrolls beneath the frosted glass.
class AppNavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigationShell({super.key, required this.navigationShell});

  static const _items = [
    AuroraNavItem(
      icon: Icons.cabin_outlined,
      selectedIcon: Icons.cabin_rounded,
      label: 'Home',
    ),
    AuroraNavItem(
      icon: Icons.eco_outlined,
      selectedIcon: Icons.eco_rounded,
      label: 'Grow',
    ),
    AuroraNavItem(
      icon: Icons.public_outlined,
      selectedIcon: Icons.public_rounded,
      label: 'World',
    ),
    AuroraNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'You',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AuroraNavBar(
              currentIndex: navigationShell.currentIndex,
              items: _items,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          ),
          // Floating "+" hovering above the bar.
          Positioned(
            right: AppSpacing.gutter,
            bottom: bottomInset + kAuroraNavBarHeight + AppSpacing.sm,
            child: AuroraFab(onTap: () => _showQuickAdd(context)),
          ),
        ],
      ),
    );
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('Add something new',
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              _QuickAddTile(
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.categoryWork,
                title: 'New task',
                subtitle: 'A one-off to tend to',
                onTap: () => Navigator.pop(sheetContext),
              ),
              const SizedBox(height: AppSpacing.xs),
              _QuickAddTile(
                icon: Icons.eco_outlined,
                color: AppColors.xpPrimary,
                title: 'New habit',
                subtitle: 'Something to nurture daily',
                onTap: () => Navigator.pop(sheetContext),
              ),
              const SizedBox(height: AppSpacing.xs),
              _QuickAddTile(
                icon: Icons.flag_outlined,
                color: AppColors.tertiary,
                title: 'New goal',
                subtitle: 'A horizon to grow toward',
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
