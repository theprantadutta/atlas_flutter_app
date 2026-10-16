import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/features/aurora/providers/nudge_provider.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/home/providers/home_provider.dart';
import 'package:atlas_flutter_app/features/home/screens/home_screen.dart';
import 'package:atlas_flutter_app/features/notifications/providers/notification_providers.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/starter_data_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

import '../helpers/golden.dart';

HomeView sampleHome({int done = 2, bool ready = true}) {
  final created = DateTime(2026, 10, 1);
  TodayItem item(String id, String title, String cat, int xp, int? minute, bool isDone) => TodayItem(
        id: id,
        kind: TodayKind.task,
        title: title,
        style: CategoryStyle.forItem(title: title, category: cat),
        xp: xp,
        done: isDone,
        createdAt: created,
        minuteOfDay: minute,
      );
  return HomeView(
    today: DateTime(2026, 10, 14),
    firstName: 'KDS',
    items: [
      item('a', 'Move your body', 'fitness', 30, 7 * 60, true),
      item('b', 'Drink enough water', 'health', 10, null, done >= 2),
      item('c', 'Read 20 pages', 'learning', 20, 21 * 60, done >= 3),
      item('d', 'Wind down', 'mindfulness', 15, 22 * 60 + 30, done >= 4),
    ],
    stats: PlayerStats(
      totalXp: 640,
      level: LevelInfo.of(640),
      streak: 12,
      bestStreak: 14,
      xpToday: 175,
      tendedToday: done,
    ),
    letter: LetterTileState.unread,
    letterId: 'r1',
    ready: ready,
  );
}

List overridesFor(HomeView view) => [
      homeProvider.overrideWithValue(view),
      unreadNotificationCountProvider.overrideWith((ref) => Stream.value(2)),
      auroraNudgeProvider.overrideWithValue(null),
      dailyRolloverProvider.overrideWithValue(null),
      starterDataProvider.overrideWith(_Chosen.new),
    ];

class _Chosen extends StarterDataController {
  @override
  StarterDataState build() => const StarterDataState(loaded: true, choiceMade: true);
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({'atlas.dayComplete.lastDate': '2026-10-14'}));

  for (final dark in [false, true]) {
    testWidgets('home ${dark ? 'dark' : 'light'}', (tester) async {
      await pumpPhone(tester, const HomeScreen(), dark: dark, overrides: overridesFor(sampleHome()));
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_${dark ? 'dark' : 'light'}.png'),
      );
    });
  }

  testWidgets('a half-loaded day passes no verdict', (tester) async {
    // Only finished items have arrived so far: everything shown is done, but
    // the day isn't, so no "All tended" and no day-done state.
    await pumpPhone(tester, const HomeScreen(),
        overrides: overridesFor(sampleHome(done: 4, ready: false)));
    await settle(tester);
    expect(find.text('All\ntended'), findsNothing);
    expect(find.text('That’s everything for today.'), findsNothing);
    expect(sampleHome(done: 4, ready: false).dayComplete, isFalse);
    expect(sampleHome(done: 4).dayComplete, isTrue);
  });
}
