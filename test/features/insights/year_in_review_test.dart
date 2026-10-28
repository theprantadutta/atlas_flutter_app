import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/features/analytics/providers/analytics_view_provider.dart';
import 'package:atlas_flutter_app/features/analytics/screens/analytics_screen.dart';
import 'package:atlas_flutter_app/features/analytics/screens/year_in_review_screen.dart';
import 'package:atlas_flutter_app/features/aurora/data/year_in_review.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_companion_providers.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/check_in/providers/check_in_providers.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';

import '../../helpers/golden.dart';
import '../../helpers/sample_data.dart';

const _full = YearInReview(
  year: 2026,
  daysTended: 212,
  totalXp: 18340,
  longestStreak: 41,
  topHabits: [
    YearHabit(id: 'a', title: 'Read 20 pages', completions: 180),
    YearHabit(id: 'b', title: 'Morning walk', completions: 150),
  ],
  bestMonth: 6,
  bestMonthXp: 2400,
  placesDiscovered: 14,
  moodSplit: {2: 10, 4: 60},
);

const _empty = YearInReview(
  year: 2026,
  daysTended: 0,
  totalXp: 0,
  longestStreak: 0,
  topHabits: [],
  bestMonth: null,
  bestMonthXp: 0,
  placesDiscovered: 0,
  moodSplit: {},
);

class _Today extends TodayNotifier {
  _Today(this.day);
  final DateTime day;
  @override
  DateTime build() => day;
}

class _Week extends SelectedWeek {
  _Week(this.monday);
  final DateTime monday;
  @override
  DateTime build() => monday;
}

Future<void> _frames(WidgetTester tester, [int n = 30]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Your year', () {
    Future<void> pumpYear(WidgetTester tester, YearInReview review) async {
      await pumpPhone(
        tester,
        const YearInReviewScreen(year: 2026),
        size: const Size(390, 1200),
        overrides: [
          yearInReviewProvider(2026).overrideWith((ref) async => review),
        ],
      );
      await _frames(tester);
    }

    testWidgets('renders the numbers on a shareable card', (tester) async {
      await pumpYear(tester, _full);
      expect(find.text('YOUR 2026'), findsOneWidget);
      expect(find.text('212'), findsOneWidget);
      expect(find.text('days tended'), findsOneWidget);
      expect(find.text('18,340'), findsOneWidget);
      expect(find.text('41'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('June'), findsOneWidget);
      expect(find.text('Read 20 pages'), findsOneWidget);
      expect(find.text('180 days'), findsOneWidget);
      expect(find.text('How it felt'), findsOneWidget);
      expect(find.text('Good 60'), findsOneWidget);
      expect(find.text('Share your year'), findsOneWidget);
      // The card is what gets captured for sharing.
      expect(
          find.ancestor(
              of: find.byType(YearInReviewCard),
              matching: find.byType(RepaintBoundary)),
          findsWidgets);
    });

    testWidgets('no moods: no mood section', (tester) async {
      await pumpYear(
        tester,
        const YearInReview(
          year: 2026,
          daysTended: 3,
          totalXp: 90,
          longestStreak: 2,
          topHabits: [],
          bestMonth: 10,
          bestMonthXp: 90,
          placesDiscovered: 0,
          moodSplit: {},
        ),
      );
      expect(find.text('How it felt'), findsNothing);
      expect(find.text('What you came back to'), findsNothing);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('empty year: a kind empty state and nothing to share',
        (tester) async {
      await pumpYear(tester, _empty);
      expect(find.text('Your 2026 starts with one day.'), findsOneWidget);
      expect(find.text('Share your year'), findsNothing);
      expect(find.byType(YearInReviewCard), findsNothing);
    });

    test('numbers are grouped', () {
      expect(groupThousands(7), '7');
      expect(groupThousands(1000), '1,000');
      expect(groupThousands(18340), '18,340');
      expect(groupThousands(1234567), '1,234,567');
    });
  });

  group('Insights entry points', () {
    Future<void> pumpInsights(WidgetTester tester, DateTime today) async {
      await pumpPhone(
        tester,
        const AnalyticsScreen(),
        size: const Size(390, 1600),
        overrides: [
          todayProvider.overrideWith(() => _Today(today)),
          selectedWeekProvider.overrideWith(() => _Week(startOfWeek(today))),
          ledgerDaysProvider.overrideWithValue(sampleLedgerWeek()),
          habitsStreamProvider.overrideWith((ref) => Stream.value(sampleHabits)),
          tasksStreamProvider.overrideWith((ref) => Stream.value(sampleTasks)),
          canDeepInsightsProvider.overrideWithValue(true),
          weekMoodsProvider.overrideWithValue(List<int?>.filled(7, null)),
        ],
      );
      await _frames(tester);
    }

    testWidgets('October: only the Your year row', (tester) async {
      await pumpInsights(tester, DateTime(2026, 10, 28));
      expect(find.byKey(const ValueKey('your-year-card')), findsNothing);
      expect(find.byKey(const ValueKey('your-year-row')), findsOneWidget);
      expect(find.text('How the week felt'), findsOneWidget);
    });

    testWidgets('from December 1st: the Your year card too', (tester) async {
      await pumpInsights(tester, DateTime(2026, 12, 1));
      expect(find.byKey(const ValueKey('your-year-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('your-year-row')), findsOneWidget);
    });
  });
}
