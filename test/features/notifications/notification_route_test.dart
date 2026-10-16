import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/features/notifications/providers/notification_providers.dart';

import '../../helpers/sample_data_extra.dart';

void main() {
  final t = DateTime(2025, 10, 14);

  test('an explicit route in data wins', () {
    expect(notificationRoute(notification('a', 't', 'b', 'systemMessage', t, data: '{"route":"/analytics"}')),
        '/analytics');
  });

  test('entities lead to their screen', () {
    expect(notificationRoute(notification('a', 't', 'b', 'x', t, entityType: 'habit')), '/grow');
    expect(notificationRoute(notification('a', 't', 'b', 'x', t, entityType: 'world_tile')), '/world');
    expect(notificationRoute(notification('a', 't', 'b', 'x', t, entityType: 'Achievement')),
        '/world/achievements');
    expect(notificationRoute(notification('a', 't', 'b', 'x', t, entityType: 'reflection')), '/aurora/letter');
  });

  test('types are the fallback, and unknown ones stay put', () {
    expect(notificationRoute(notification('a', 't', 'b', 'taskReminder', t)), '/grow');
    expect(notificationRoute(notification('a', 't', 'b', 'level_up', t)), '/profile');
    expect(notificationRoute(notification('a', 't', 'b', 'systemMessage', t)), isNull);
    expect(notificationRoute(notification('a', 't', 'b', 'systemMessage', t, data: 'not json')), isNull);
  });

  test('new inbox kinds lead to real places', () {
    final t = DateTime(2026, 10, 15);
    expect(notificationRoute(notification('a', 't', 'b', 'achievement', t, data: '{"kind":"achievement"}')),
        '/world/achievements');
    expect(notificationRoute(notification('a', 't', 'b', 'place', t, data: '{"kind":"place"}')), '/world');
    expect(notificationRoute(notification('a', 't', 'b', 'letter', t, data: '{"kind":"letter"}')), '/aurora/letter');
    expect(notificationRoute(notification('a', 't', 'b', 'systemMessage', t, data: '{"kind":"account","route":"/paywall"}')),
        '/paywall');
  });

  test('routes the app does not have are never followed', () {
    final t = DateTime(2026, 10, 15);
    // What the old server jobs sent.
    expect(notificationRoute(notification('a', 't', 'b', 'dailySummary', t, data: '{"route":"/dashboard"}')),
        '/analytics');
    expect(notificationRoute(notification('a', 't', 'b', 'taskReminder', t, data: '{"route":"/tasks/42"}')), '/grow');
  });
}
