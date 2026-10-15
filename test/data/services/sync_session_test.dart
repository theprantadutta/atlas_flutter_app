import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/data/services/offline_manager.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';

void main() {
  group('OfflineManager.parseSyncTimestamp', () {
    test('keeps an explicit UTC instant', () {
      expect(
        OfflineManager.parseSyncTimestamp('2026-10-15T08:30:00.123Z'),
        DateTime.utc(2026, 10, 15, 8, 30, 0, 123),
      );
    });

    test('treats a zoneless server value as UTC, not device-local', () {
      expect(
        OfflineManager.parseSyncTimestamp('2026-10-15T08:30:00.1234567'),
        DateTime.utc(2026, 10, 15, 8, 30, 0, 123, 456),
      );
    });

    test('honours an explicit offset', () {
      expect(
        OfflineManager.parseSyncTimestamp('2026-10-15T14:30:00+06:00'),
        DateTime.utc(2026, 10, 15, 8, 30),
      );
    });

    test('missing, empty or default values keep the previous cursor', () {
      expect(OfflineManager.parseSyncTimestamp(null), isNull);
      expect(OfflineManager.parseSyncTimestamp(''), isNull);
      expect(OfflineManager.parseSyncTimestamp('garbage'), isNull);
      expect(
          OfflineManager.parseSyncTimestamp('0001-01-01T00:00:00'), isNull);
    });
  });

  group('logout pref classification', () {
    test('user-scoped keys are removed', () {
      for (final key in [
        'offline_manager_last_sync',
        'atlas_setup_complete',
        'atlas_starter_choice_made',
        'atlas_starter_seeded',
        'atlas.snoozed.v1',
        'atlas.dayComplete.lastDate',
        'atlas.letter.lastReadId',
        'atlas.discovered.celebrated',
        'atlas_aurora_preferred_name',
        'atlas_aurora_intention',
      ]) {
        expect(AuthNotifier.isUserScopedPrefKey(key), isTrue, reason: key);
      }
    });

    test('device-level keys survive', () {
      for (final key in [
        'atlas_theme_mode',
        'atlas_high_refresh_rate',
        'atlas_notification_primer_shown',
        'atlas_intro_seen',
        'atlas_legal_accepted_version',
        'atlas_coach_marks_seen',
        'billing_pending_verifications',
      ]) {
        expect(AuthNotifier.isUserScopedPrefKey(key), isFalse, reason: key);
      }
    });
  });
}
