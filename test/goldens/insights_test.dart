import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/features/analytics/screens/analytics_screen.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';

import '../helpers/golden.dart';
import '../helpers/sample_data.dart';

class _Sunday extends TodayNotifier {
  @override
  DateTime build() => addDays(startOfWeek(kToday), 6);
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('insights $mode', (tester) async {
      await pumpPhone(tester, const AnalyticsScreen(), dark: dark, overrides: [
        todayProvider.overrideWith(_Sunday.new),
        ledgerDaysProvider.overrideWithValue(sampleLedgerWeek()),
        habitsStreamProvider.overrideWith((ref) => Stream.value(sampleHabits)),
        tasksStreamProvider.overrideWith((ref) => Stream.value(sampleTasks)),
        canDeepInsightsProvider.overrideWithValue(true),
      ]);
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/insights_$mode.png'));
    });
  }
}
