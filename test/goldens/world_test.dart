import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/features/world/providers/world_view.dart';
import 'package:atlas_flutter_app/features/world/screens/world_screen.dart';

import '../helpers/golden.dart';
import '../helpers/sample_data.dart';

WorldView sampleWorld() {
  final places = sampleTiles().map(placeFor).toList();
  final locked = places.where((p) => !p.discovered).toList()
    ..sort((a, b) => a.tile.unlockRequirement.compareTo(b.tile.unlockRequirement));
  return WorldView(
    places: places,
    next: locked.first,
    totalXp: locked.first.tile.unlockRequirement - 7,
    previousThreshold: places.where((p) => p.discovered).map((p) => p.tile.unlockRequirement).reduce(math.max),
  );
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('world $mode', (tester) async {
      await pumpPhone(tester, const WorldScreen(), dark: dark, overrides: [
        worldViewProvider.overrideWithValue(sampleWorld()),
      ]);
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/world_$mode.png'));
    });
  }
}
