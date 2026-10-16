import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';
import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/features/world/providers/world_view.dart';
import 'package:atlas_flutter_app/features/world/widgets/atlas_globe.dart';
import 'package:atlas_flutter_app/shared/widgets/aurora_nav_bar.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Your Atlas: a slowly turning globe of the places you've discovered by
/// tending yourself, the next one always in view.
class WorldScreen extends ConsumerStatefulWidget {
  const WorldScreen({super.key});

  @override
  ConsumerState<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends ConsumerState<WorldScreen> {
  final _globe = GlobalKey<AtlasGlobeState>();
  String? _celebrating;
  int _burst = 0;

  void _maybeCelebrate(List<String> pending, WorldView view) {
    if (_celebrating != null || pending.isEmpty) return;
    final id = pending.first;
    final place = view.places.where((p) => p.id == id).firstOrNull;
    if (place == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _celebrating = id);
      // Let the globe turn to it and the pin land.
      await Future<void>.delayed(AppMotion.deliberate + AppMotion.medium);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _burst++);
      await ref.read(pendingDiscoveriesProvider.notifier).celebrated(id);
      await Future<void>.delayed(AppMotion.fast);
      if (!mounted) return;
      await _discoverySheet(place);
      if (mounted) setState(() => _celebrating = null);
    });
  }

  Future<void> _discoverySheet(Place place) => showAtlasSheet<void>(
        context,
        builder: (context) {
          final p = context.palette;
          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientIconTile(icon: place.icon, size: 64),
                const SizedBox(height: AppSpacing.md),
                Text('You discovered', style: AppTypography.dateLine.copyWith(color: p.textMuted)),
                const SizedBox(height: 4),
                Text(place.name,
                    textAlign: TextAlign.center,
                    style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text('Every day you tend yourself, the world gets a little bigger.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(color: p.textBody)),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [
                  Expanded(
                    child: PillButton(
                      label: 'Visit',
                      height: 52,
                      expand: true,
                      onTap: () {
                        Navigator.of(context).pop();
                        _openPlace(place);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: PillButton(
                      label: 'Close',
                      variant: PillVariant.track,
                      height: 52,
                      expand: true,
                      haptic: PressHaptic.selection,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ]),
              ],
            ),
          );
        },
      );

  void _openPlace(Place place) {
    _globe.currentState?.focusOn(place);
    showAtlasSheet<void>(context, builder: (_) => _PlaceSheet(place: place));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final view = ref.watch(worldViewProvider);
    final pending = ref.watch(pendingDiscoveriesProvider);
    if (view != null) _maybeCelebrate(pending, view);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: ref.watch(tabScrollControllersProvider).of(3),
          padding: readableInsets(context, top: AppSpacing.sm, bottom: navScrollPadding(context)),
          children: [
            ScreenHeader(
              title: 'Your Atlas',
              subtitle: view == null
                  ? ' '
                  : '${view.aliveCount} of ${view.places.length} places discovered',
              trailing: CircleIconButton(
                icon: Symbols.trophy_rounded,
                filled: true,
                iconColor: AppColors.amber,
                semanticLabel: 'Achievements',
                onTap: () => context.push('/world/achievements'),
              ),
            ),
            if (view == null) ...[
              const SizedBox(height: AppSpacing.lg),
              const Center(child: Skeleton(height: 300, width: 300, radius: 150)),
            ] else ...[
              SizedBox(
                height: 372,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -8,
                      child: AtlasGlobe(
                        key: _globe,
                        places: view.places,
                        nextId: view.next?.id,
                        dropId: _celebrating,
                        onTapPlace: (place) => showAtlasSheet<void>(
                          context,
                          builder: (_) => _PlaceSheet(place: place),
                        ),
                      ),
                    ),
                    SparkBurst(trigger: _burst, radius: 110),
                  ],
                ),
              ),
              if (view.next != null) _NextCard(view: view) else const _AllFound(),
              const SizedBox(height: 10),
              if (view.discovered.isNotEmpty)
                LayoutBuilder(builder: (context, c) {
                  final w = (c.maxWidth - 16) / 3;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < view.discovered.length; i++)
                        SizedBox(
                          width: w,
                          child: EntryFade(
                            id: 'place-${view.discovered[i].id}',
                            index: i,
                            child: _PlaceTile(
                              place: view.discovered[i],
                              onTap: () => _openPlace(view.discovered[i]),
                            ),
                          ),
                        ),
                    ],
                  );
                })
              else
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text('Your first places appear here as you tend.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(color: p.textMuted)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.view});
  final WorldView view;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final next = view.next!;
    final on = p.onRaised;
    return AtlasTile.raised(
      context,
      semanticLabel: 'Next place: ${next.name}, ${view.xpToGo} XP to go',
      child: Row(
        children: [
          GradientIconTile(icon: next.icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                    child: Text('Next: ${next.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.rowTitle.copyWith(color: on)),
                  ),
                  CountUpText(
                    value: view.xpToGo,
                    suffix: ' XP',
                    style: AppTypography.metaStrong.copyWith(color: on.withValues(alpha: .7)),
                  ),
                ]),
                const SizedBox(height: 7),
                GradientBar(
                  value: view.nextProgress,
                  gradient: AppColors.sunriseBar,
                  trackColor: on.withValues(alpha: .15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllFound extends StatelessWidget {
  const _AllFound();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AtlasTile.raised(
      context,
      child: Row(children: [
        const AtlasSpark(size: 40, animated: true),
        const SizedBox(width: 14),
        Expanded(
          child: Text('You’ve found every place. Keep tending; your world remembers.',
              style: AppTypography.rowTitle.copyWith(color: p.onRaised)),
        ),
      ]),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final found = place.tile.unlockedAt;
    return AtlasTile(
      radius: AppSpacing.radiusButton,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      semanticLabel: place.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(style: CategoryStyle(place.icon, place.color), size: 34),
          const SizedBox(height: 8),
          Text(place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.tileTitle.copyWith(color: p.textPrimary)),
          Text(found == null ? 'Found' : 'Found ${monthShort(found)} ${found.day}',
              style: AppTypography.tiny.copyWith(color: p.textMuted)),
        ],
      ),
    );
  }
}

/// A place up close: when you found it and what you tended that day.
class _PlaceSheet extends ConsumerWidget {
  const _PlaceSheet({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final found = place.tile.unlockedAt;
    final days = ref.watch(ledgerDaysProvider);
    final habits = ref.watch(habitsStreamProvider).value ?? const [];
    final tasks = ref.watch(tasksStreamProvider).value ?? const [];
    final day = found == null ? null : LedgerMath.dayOf(days, found);
    final titles = <String>[
      if (day != null)
        for (final key in day.items.keys)
          if (key.startsWith('h:'))
            ?habits.where((h) => Ledger.habitKey(h.id) == key).firstOrNull?.title
          else if (key.startsWith('t:'))
            ?tasks.where((t) => Ledger.taskKey(t.id) == key).firstOrNull?.title,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            place.discovered
                ? IconTile(style: CategoryStyle(place.icon, place.color), size: 48)
                : GradientIconTile(icon: place.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(place.name, style: AppTypography.section.copyWith(color: p.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  place.discovered
                      ? (found == null ? 'Discovered' : 'Found ${longDate(found)}')
                      : 'Opens at ${place.tile.unlockRequirement} XP',
                  style: AppTypography.meta.copyWith(color: p.textMuted),
                ),
              ]),
            ),
          ]),
          if (place.discovered) ...[
            const SizedBox(height: AppSpacing.lg - 4),
            Text('WHAT GOT YOU HERE',
                style: AppTypography.kicker.copyWith(color: p.textMuted)),
            const SizedBox(height: AppSpacing.xs),
            if (titles.isEmpty)
              Text('Showing up, a little at a time.',
                  style: AppTypography.body.copyWith(color: p.textBody))
            else
              for (final t in titles.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const AtlasSpark(size: 12),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t, style: AppTypography.body.copyWith(color: p.textBody))),
                  ]),
                ),
            const SizedBox(height: AppSpacing.xs),
            Text('${place.tile.unlockRequirement} XP to discover',
                style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
          ],
        ],
      ),
    );
  }
}
