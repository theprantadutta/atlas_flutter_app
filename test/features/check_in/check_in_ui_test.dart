import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart' show CheckIn;
import 'package:atlas_flutter_app/features/aurora/providers/nudge_provider.dart';
import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';
import 'package:atlas_flutter_app/features/check_in/providers/check_in_providers.dart';
import 'package:atlas_flutter_app/features/check_in/widgets/check_in_sheet.dart';
import 'package:atlas_flutter_app/features/check_in/widgets/mood_strip.dart';
import 'package:atlas_flutter_app/features/home/widgets/check_in_card.dart';

import '../../helpers/golden.dart';

final _morning = DateTime(2026, 10, 28, 8, 30);
final _evening = DateTime(2026, 10, 28, 19);

CheckIn _row(CheckInMoment moment, int mood, {String? note}) {
  final at = DateTime(2026, 10, 28, 8);
  return CheckIn(
    id: 'c-${moment.wire}',
    userId: 'u1',
    date: DateTime(2026, 10, 28),
    moment: moment.wire,
    mood: mood,
    note: note,
    auroraReply: null,
    createdAt: at,
    updatedAt: at,
    isDirty: true,
    isDeleted: false,
    deletedAt: null,
    lastSyncedAt: null,
  );
}

/// Dismissals kept in memory (the real one persists to preferences).
class _Dismissals extends CheckInDismissalsNotifier {
  @override
  Set<CheckInMoment> build() => const {};

  @override
  Future<void> dismiss(CheckInMoment moment) async =>
      state = {...state, moment};
}

/// The real prompt rule, at a fixed time instead of the clock.
List _promptAt(DateTime now, {List<CheckIn> today = const []}) => [
      todayCheckInsProvider.overrideWith((ref) => Stream.value(today)),
      checkInDismissalsProvider.overrideWith(_Dismissals.new),
      checkInPromptProvider.overrideWith((ref) {
        final rows = ref.watch(todayCheckInsProvider).value ?? const <CheckIn>[];
        return dueCheckInMoment(
          now,
          done: {for (final c in rows) CheckInMoment.fromWire(c.moment)},
          dismissed: ref.watch(checkInDismissalsProvider),
        );
      }),
    ];

const _nudge = AuroraNudge(
  key: 'n1',
  tone: NudgeTone.gentle,
  icon: Symbols.spa_rounded,
  message: 'A gentle nudge from Aurora',
);

/// A controller that answers the way [_reply] says, without a database or
/// network.
class _FakeController extends CheckInController {
  _FakeController(this._reply);
  final CheckInState Function(CheckIn row) _reply;
  static ({int mood, CheckInMoment moment, String? note})? lastSave;

  @override
  Future<CheckIn?> save({
    required int mood,
    required CheckInMoment moment,
    String? note,
  }) async {
    lastSave = (mood: mood, moment: moment, note: note);
    final row = _row(moment, mood, note: note);
    state = CheckInState(checkIn: row, awaitingReply: true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = _reply(row);
    return row;
  }
}

Future<void> _pumpFrames(WidgetTester tester, [int n = 20]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpSlot(WidgetTester tester, List overrides) async {
  await pumpPhone(
    tester,
    const Scaffold(body: Padding(padding: EdgeInsets.all(20), child: HomeAuroraSlot())),
    overrides: [auroraNudgeProvider.overrideWithValue(_nudge), ...overrides],
  );
  await _pumpFrames(tester, 6);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Home check-in card', () {
    testWidgets('morning: shows the morning question, and holds the nudge back',
        (tester) async {
      await _pumpSlot(tester, _promptAt(_morning));
      expect(find.text('How are you starting the day?'), findsOneWidget);
      expect(find.text('Morning check-in'), findsOneWidget);
      expect(find.text('A gentle nudge from Aurora'), findsNothing);
    });

    testWidgets('evening: shows the evening question', (tester) async {
      await _pumpSlot(tester, _promptAt(_evening));
      expect(find.text('How did today feel?'), findsOneWidget);
      expect(find.text('Evening check-in'), findsOneWidget);
    });

    testWidgets('midday: hidden, and the nudge shows instead', (tester) async {
      await _pumpSlot(tester, _promptAt(DateTime(2026, 10, 28, 14)));
      expect(find.byKey(const ValueKey('check-in-card')), findsNothing);
      expect(find.text('A gentle nudge from Aurora'), findsOneWidget);
    });

    testWidgets('done for the moment: hidden', (tester) async {
      await _pumpSlot(tester,
          _promptAt(_morning, today: [_row(CheckInMoment.morning, 4)]));
      expect(find.byKey(const ValueKey('check-in-card')), findsNothing);
    });

    testWidgets('dismissed for today: hidden', (tester) async {
      await _pumpSlot(tester, _promptAt(_morning));
      expect(find.byKey(const ValueKey('check-in-card')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('check-in-dismiss')));
      await _pumpFrames(tester, 4);
      expect(find.byKey(const ValueKey('check-in-card')), findsNothing);
      // The nudge was only waiting its turn.
      expect(find.text('A gentle nudge from Aurora'), findsOneWidget);
    });

    testWidgets('tapping the card opens the sheet for that moment',
        (tester) async {
      await _pumpSlot(tester, _promptAt(_evening));
      await tester.tap(find.text('Check in'));
      await _pumpFrames(tester);
      expect(find.text('EVENING CHECK-IN'), findsOneWidget);
    });

    test('the prompt refreshes at the window edges', () {
      expect(nextCheckInBoundary(_morning), DateTime(2026, 10, 28, 12, 0, 1));
      expect(nextCheckInBoundary(DateTime(2026, 10, 28, 13)),
          DateTime(2026, 10, 28, 17, 0, 1));
      expect(nextCheckInBoundary(_evening), DateTime(2026, 10, 29, 0, 0, 1));
    });
  });

  group('Check-in sheet', () {
    Future<void> openSheet(
      WidgetTester tester, {
      required CheckInState Function(CheckIn row) reply,
      List<CheckIn> today = const [],
      CheckInMoment? moment = CheckInMoment.morning,
    }) async {
      await pumpPhone(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showCheckInSheet(context, moment: moment),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        overrides: [
          todayCheckInsProvider.overrideWith((ref) => Stream.value(today)),
          checkInControllerProvider
              .overrideWith(() => _FakeController(reply)),
        ],
      );
      await tester.tap(find.text('open'));
      await _pumpFrames(tester);
    }

    Future<void> pickAndSave(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('mood-4')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const ValueKey('check-in-note')), 'slept well');
      await tester.tap(find.text('Save'));
      await tester.pump();
    }

    testWidgets('greets by moment and needs a mood before saving',
        (tester) async {
      await openSheet(tester, reply: (row) => CheckInState(checkIn: row));
      expect(find.text('How are you starting the day?'), findsOneWidget);
      for (final label in CheckInMood.labels.values) {
        expect(find.text(label), findsOneWidget);
      }
      _FakeController.lastSave = null;
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(_FakeController.lastSave, isNull);
    });

    testWidgets('saving shows the gentle wait, then Aurora\'s reply',
        (tester) async {
      await openSheet(tester,
          reply: (row) => CheckInState(
              checkIn: row, reply: 'A good start. Keep it gentle today.'));
      await pickAndSave(tester);
      await _pumpFrames(tester, 4);
      expect(find.text('Aurora is reading your check-in'), findsOneWidget);
      expect(_FakeController.lastSave?.mood, 4);
      expect(_FakeController.lastSave?.note, 'slept well');
      expect(_FakeController.lastSave?.moment, CheckInMoment.morning);

      await _pumpFrames(tester);
      expect(find.text('A good start. Keep it gentle today.'), findsOneWidget);
      expect(find.text(checkInPremiumLine), findsNothing);
      expect(find.text('Saved. Thank you for checking in.'), findsOneWidget);
    });

    testWidgets('402 shows the quiet premium line', (tester) async {
      await openSheet(tester,
          reply: (row) => CheckInState(
              checkIn: row, replyMiss: CheckInReplyMiss.premium));
      await pickAndSave(tester);
      await _pumpFrames(tester);
      expect(find.text(checkInPremiumLine), findsOneWidget);
    });

    testWidgets('offline shows the quiet premium line too', (tester) async {
      await openSheet(tester,
          reply: (row) => CheckInState(
              checkIn: row, replyMiss: CheckInReplyMiss.offline));
      await pickAndSave(tester);
      await _pumpFrames(tester);
      expect(find.text(checkInPremiumLine), findsOneWidget);
    });

    testWidgets('a failed reply shows nothing extra', (tester) async {
      await openSheet(tester,
          reply: (row) =>
              CheckInState(checkIn: row, replyMiss: CheckInReplyMiss.failed));
      await pickAndSave(tester);
      await _pumpFrames(tester);
      expect(find.text('Saved. Thank you for checking in.'), findsOneWidget);
      expect(find.text(checkInPremiumLine), findsNothing);
      expect(find.text('Aurora is reading your check-in'), findsNothing);
    });

    testWidgets('an existing check-in opens for editing', (tester) async {
      await openSheet(tester,
          moment: CheckInMoment.evening,
          today: [_row(CheckInMoment.evening, 2, note: 'long day')],
          reply: (row) => CheckInState(checkIn: row));
      expect(find.text('How did today feel?'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('long day'), findsOneWidget);
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      expect(_FakeController.lastSave?.mood, 2);
      expect(_FakeController.lastSave?.moment, CheckInMoment.evening);
      await _pumpFrames(tester);
    });

    test('the default moment follows the time of day', () {
      expect(checkInMomentFor(_morning), CheckInMoment.morning);
      expect(checkInMomentFor(_evening), CheckInMoment.evening);
      final noon = DateTime(2026, 10, 28, 13);
      expect(checkInMomentFor(noon), CheckInMoment.morning);
      expect(checkInMomentFor(noon, done: {CheckInMoment.morning}),
          CheckInMoment.evening);
    });
  });

  group('Mood strip', () {
    final today = DateTime(2026, 10, 28); // a Wednesday

    Future<void> pumpStrip(WidgetTester tester, List<int?> moods,
        {VoidCallback? onCheckIn}) async {
      await pumpPhone(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: WeekMoodStrip(moods: moods, today: today, onCheckIn: onCheckIn),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('empty: seven rings and an invitation', (tester) async {
      var opened = false;
      await pumpStrip(tester, List.filled(7, null), onCheckIn: () => opened = true);
      expect(find.text('How the week felt'), findsOneWidget);
      expect(find.byKey(const ValueKey('mood-dot-null')), findsNWidgets(7));
      expect(find.text('Check in once and your week starts to show here.'),
          findsOneWidget);
      await tester.tap(find.text('Check in'));
      expect(opened, isTrue);
    });

    testWidgets('filled: coloured dots oldest to newest, with a legend',
        (tester) async {
      await pumpStrip(tester, const [1, null, 3, 5, 2, 4, 5]);
      expect(find.byKey(const ValueKey('mood-dot-null')), findsOneWidget);
      expect(find.byKey(const ValueKey('mood-dot-5')), findsNWidgets(2));
      expect(find.text('Check in once and your week starts to show here.'),
          findsNothing);
      for (final l in ['Heavy', 'Low', 'Okay', 'Good', 'Bright']) {
        expect(find.text(l), findsOneWidget);
      }
      // Oldest first: Thursday to today (Wednesday).
      final letters = tester
          .widgetList<Text>(find.descendant(
              of: find.byType(WeekMoodStrip), matching: find.byType(Text)))
          .map((t) => t.data)
          .where((d) => d != null && d.length == 1)
          .toList();
      expect(letters, ['T', 'F', 'S', 'S', 'M', 'T', 'W']);
      expect(find.bySemanticsLabel('Wednesday: Bright'), findsOneWidget);
      expect(find.bySemanticsLabel('Friday: no check-in'), findsOneWidget);
    });
  });
}
