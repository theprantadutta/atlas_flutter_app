import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

import '../helpers/golden.dart';

class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final read = CategoryStyle.forItem(title: 'Read 20 pages', category: 'mindfulness');
    final sleep = CategoryStyle.forItem(title: 'Wind down', category: 'learning');
    final water = CategoryStyle.forItem(title: 'Drink enough water', category: 'health');
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            ScreenHeader(
              title: 'Grow',
              trailing: CircleIconButton(
                icon: Symbols.search_rounded,
                onTap: () {},
                semanticLabel: 'Search',
              ),
            ),
            const SizedBox(height: 16),
            SegmentedPill(labels: const ['Tasks', 'Habits', 'Goals'], index: 1, onChanged: (_) {}),
            const SizedBox(height: 16),
            InkHeroCard(
              height: 180,
              glowLevel: .5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text('Today', style: AppTypography.dateLine.copyWith(color: p.onRaised.withValues(alpha: .7))),
                    const Spacer(),
                    AtlasChip(
                      label: '12 days',
                      icon: Symbols.local_fire_department_rounded,
                      iconColor: AppColors.sunriseA,
                      background: p.onRaised.withValues(alpha: .12),
                      foreground: p.onRaised,
                      dense: true,
                    ),
                  ]),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('50', style: AppTypography.heroNumber.copyWith(color: p.onRaised)),
                    GradientText('%', style: AppTypography.heroNumber),
                  ]),
                  const ProgressSegments(total: 4, done: 2),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AtlasRow(
              leading: IconTile(style: read),
              title: 'Read 20 pages',
              meta: '9:00 pm · +20 XP',
              trailing: PillButton(label: 'Tend', onTap: () {}),
              onSwipeRight: () {},
            ),
            const SizedBox(height: 8),
            AtlasRow(
              leading: IconTile(style: sleep),
              title: 'Wind down',
              meta: '10:30 pm · +15 XP',
              trailing: PillButton(label: 'Later', variant: PillVariant.track, onTap: () {}),
            ),
            const SizedBox(height: 8),
            AtlasRow(
              minHeight: 70,
              leading: IconTile(style: water, size: 44),
              title: 'Drink enough water',
              meta: '6 of 6 glasses',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Sparkline7(days: const [true, true, true, false, true, true, true], color: water.fg(context), seed: 'w'),
                const SizedBox(width: 4),
                const CheckCircle(done: true),
              ]),
            ),
            const SizedBox(height: 8),
            AtlasRow(
              minHeight: 70,
              leading: IconTile(style: sleep, size: 44),
              title: 'Wind down before bed',
              meta: '10:30 pm',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Sparkline7(days: const [true, true, false, true, true, true, false], color: AppColors.violet, seed: 'x'),
                const SizedBox(width: 4),
                const CheckCircle(done: false),
              ]),
            ),
            const SizedBox(height: 16),
            AtlasTile(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (var i = 0; i < 7; i++)
                  DayRing(value: [1.0, .45, 0.0, 0.0, 0.0, 0.0, 0.0][i], label: '${13 + i}'),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              const AtlasSpark(size: 40),
              const SizedBox(width: 12),
              const AvatarRing(name: 'KDS'),
              const SizedBox(width: 12),
              AtlasChip.success(context, '18%', icon: Symbols.arrow_upward_rounded),
              const SizedBox(width: 12),
              PillButton(label: 'Add', variant: PillVariant.gradient, height: 34, onTap: () {}),
            ]),
            const SizedBox(height: 16),
            const GradientBar(value: .72, gradient: AppColors.sunriseBar),
            const SizedBox(height: 16),
            LinkRow(icon: Symbols.edit_note_rounded, iconColor: AppColors.coral, label: 'Tell it the way it is', onTap: () {}),
          ],
        ),
      ),
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  for (final dark in [false, true]) {
    testWidgets('component gallery ${dark ? 'dark' : 'light'}', (tester) async {
      await pumpPhone(tester, const _Gallery(), dark: dark);
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/components_${dark ? 'dark' : 'light'}.png'),
      );
    });
  }
}
