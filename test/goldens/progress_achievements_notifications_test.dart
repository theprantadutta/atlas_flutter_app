import 'package:clock/clock.dart';
// Hide Flutter's Notification: these tests use the Drift row.
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/achievements/providers/achievement_providers.dart';
import 'package:atlas_flutter_app/features/achievements/screens/achievements_screen.dart';
import 'package:atlas_flutter_app/features/avatar/providers/avatar_providers.dart';
import 'package:atlas_flutter_app/features/avatar/screens/avatar_screen.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/goals/providers/goal_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/notifications/providers/notification_providers.dart';
import 'package:atlas_flutter_app/features/notifications/screens/notification_center_screen.dart';
import 'package:atlas_flutter_app/features/progress/providers/progress_providers.dart';
import 'package:atlas_flutter_app/features/progress/screens/progress_screen.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';

import '../helpers/golden.dart';
import '../helpers/sample_data.dart';
import '../helpers/sample_data_extra.dart';

class _FixedToday extends TodayNotifier {
  @override
  DateTime build() => kToday;
}

final _avatar = Avatar(
  id: 'av',
  userId: 'u',
  name: 'Kestrel',
  level: 4,
  currentXp: 640,
  strength: 17,
  wisdom: 14,
  intelligence: 12,
  appearanceData: avatarAppearanceJson(skin: 1, hair: 3, outfit: 0),
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
  isDirty: false,
  isDeleted: false,
);

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('progress $mode', (tester) async {
      await pumpPhone(tester, const ProgressScreen(), dark: dark, overrides: [
        todayProvider.overrideWith(_FixedToday.new),
        ledgerDaysProvider.overrideWithValue(sampleLedger()),
        progressEntriesStreamProvider.overrideWith((ref) => Stream.value(const <ProgressEntry>[])),
        habitsStreamProvider.overrideWith((ref) => Stream.value(sampleHabits)),
        tasksStreamProvider.overrideWith((ref) => Stream.value(sampleTasks)),
        goalsStreamProvider.overrideWith((ref) => Stream.value(sampleGoals)),
      ]);
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/progress_$mode.png'));
    });

    testWidgets('achievements $mode', (tester) async {
      await pumpPhone(tester, const AchievementsScreen(), dark: dark, overrides: [
        achievementsStreamProvider.overrideWith((ref) => Stream.value(sampleAchievements())),
      ]);
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/achievements_$mode.png'));
    });

    testWidgets('notifications $mode', (tester) async {
      // Relative times ("Yesterday", a weekday, a date) follow the clock, so
      // pin it: the golden must not change because the calendar did.
      final now = DateTime(2026, 10, 15, 12);
      await withClock(Clock.fixed(now), () async {
        await pumpPhone(tester, const NotificationCenterScreen(), dark: dark, overrides: [
          notificationsStreamProvider.overrideWith((ref) => Stream.value(sampleNotifications(now))),
        ]);
        await settle(tester);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/notifications_$mode.png'));
      });
    });

    testWidgets('avatar $mode', (tester) async {
      await pumpPhone(tester, const AvatarScreen(), dark: dark, overrides: [
        avatarStreamProvider.overrideWith((ref) => Stream.value(_avatar)),
      ]);
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/avatar_$mode.png'));
    });
  }
}
