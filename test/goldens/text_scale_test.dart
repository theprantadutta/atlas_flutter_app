import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/features/analytics/screens/analytics_screen.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/aurora/screens/aurora_chat_screen.dart';
import 'package:atlas_flutter_app/features/aurora/screens/aurora_screen.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/grow/screens/grow_screen.dart';
import 'package:atlas_flutter_app/features/home/screens/home_screen.dart';
import 'package:atlas_flutter_app/features/world/providers/world_view.dart';
import 'package:atlas_flutter_app/features/world/screens/world_screen.dart';

import '../helpers/golden.dart';
import '../helpers/sample_data.dart';
import 'aurora_test.dart' as aurora;
import 'grow_test.dart' as grow;
import 'home_test.dart' as home;
import 'world_test.dart' as world;

/// Large text (1.3x) must never overflow: rows grow instead of clipping.
void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final screens = <String, (Widget, List)>{
    'home': (const HomeScreen(), home.overridesFor(home.sampleHome())),
    'grow': (const GrowScreen(), grow.growOverrides()),
    'aurora': (
      const AuroraScreen(),
      [...aurora.common(), latestReflectionProvider.overrideWith((ref) => Stream.value(aurora.sampleLetter))]
    ),
    'chat': (const AuroraChatScreen(), [...aurora.common(), auroraChatProvider.overrideWith(aurora.SampleChat.new)]),
    'world': (const WorldScreen(), [worldViewProvider.overrideWithValue(world.sampleWorld())]),
    'insights': (
      const AnalyticsScreen(),
      [...grow.growOverrides().where((o) => !identical((o as dynamic).origin, ledgerDaysProvider)), ledgerDaysProvider.overrideWithValue(sampleLedgerWeek()), canDeepInsightsProvider.overrideWithValue(true)]
    ),
  };

  for (final e in screens.entries) {
    testWidgets('${e.key} at 1.3x text has no overflow', (tester) async {
      await pumpPhone(
        tester,
        MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.3,
          maxScaleFactor: 1.3,
          child: e.value.$1,
        ),
        overrides: e.value.$2,
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  }

  for (final e in screens.entries) {
    testWidgets('${e.key} runs no loops under reduced motion', (tester) async {
      await pumpPhone(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: e.value.$1,
          ),
        ),
        overrides: e.value.$2,
      );
      // Times out if any ambient loop (glow, spark, globe, ping, shimmer)
      // is still ticking.
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5));
    });
  }
}
