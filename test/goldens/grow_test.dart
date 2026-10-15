import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/goals/providers/goal_providers.dart';
import 'package:atlas_flutter_app/features/grow/screens/grow_screen.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';

import '../helpers/golden.dart';
import '../helpers/sample_data.dart';

class FixedToday extends TodayNotifier {
  @override
  DateTime build() => kToday;
}

List growOverrides() => [
      todayProvider.overrideWith(FixedToday.new),
      habitsStreamProvider.overrideWith((ref) => Stream.value(sampleHabits)),
      tasksStreamProvider.overrideWith((ref) => Stream.value(sampleTasks)),
      goalsStreamProvider.overrideWith((ref) => Stream.value(sampleGoals)),
      ledgerDaysProvider.overrideWithValue(sampleLedger()),
      dailyRolloverProvider.overrideWithValue(null),
    ];

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final dark in [false, true]) {
    testWidgets('grow habits ${dark ? 'dark' : 'light'}', (tester) async {
      await pumpPhone(tester, const GrowScreen(), dark: dark, overrides: growOverrides());
      await settle(tester);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/grow_habits_${dark ? 'dark' : 'light'}.png'));
    });
  }

  for (final tab in ['Tasks', 'Goals']) {
    testWidgets('grow $tab light', (tester) async {
      await pumpPhone(tester, const GrowScreen(), overrides: growOverrides());
      await settle(tester);
      await tester.tap(find.text(tab));
      await settle(tester);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/grow_${tab.toLowerCase()}_light.png'));
    });
  }
}
