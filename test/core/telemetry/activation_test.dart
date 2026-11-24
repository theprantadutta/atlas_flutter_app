import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/telemetry/activation.dart';

(String, Object?)? _flat((String, Map<String, Object>)? e) =>
    e == null ? null : (e.$1, e.$2['minutes']);

void main() {
  late DateTime now;
  late SharedPreferences prefs;
  Activation activation() => Activation(prefs, now: () => now);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 11, 24, 9);
  });

  test('someone who never went through setup reports nothing', () async {
    expect(await activation().tended(), isNull);
  });

  test('a new account reports its first and third tend with the minutes taken', () async {
    await activation().setupFinished();
    now = now.add(const Duration(minutes: 4));
    expect(_flat(await activation().tended()), ('first_tend', 4));
    expect(await activation().tended(), isNull);
    now = now.add(const Duration(hours: 2));
    expect(_flat(await activation().tended()), ('day0_three_tends', 124));
    expect(await activation().tended(), isNull);
  });

  test('nothing is reported after the first 24 hours', () async {
    await activation().setupFinished();
    now = now.add(const Duration(hours: 25));
    expect(await activation().tended(), isNull);
  });

  test('finishing setup again does not restart the clock', () async {
    await activation().setupFinished();
    now = now.add(const Duration(minutes: 30));
    await activation().setupFinished();
    expect(_flat(await activation().tended()), ('first_tend', 30));
  });
}
