import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/shared/themes/app_theme.dart';

/// Real fonts for goldens: Funnel Display / Funnel Sans from assets, Material
/// Symbols from its package, and the Material icon font from the SDK.
Future<void> loadAppFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  const d = 'assets/fonts/FunnelDisplay';
  const s = 'assets/fonts/FunnelSans';
  await family('FunnelDisplay', [
    '$d-Regular.ttf', '$d-Medium.ttf', '$d-SemiBold.ttf', '$d-Bold.ttf', '$d-ExtraBold.ttf',
  ]);
  await family('FunnelSans', [
    '$s-Regular.ttf', '$s-Italic.ttf', '$s-Medium.ttf', '$s-SemiBold.ttf',
    '$s-SemiBoldItalic.ttf', '$s-Bold.ttf', '$s-ExtraBold.ttf',
  ]);
  await family('packages/material_symbols_icons/MaterialSymbolsRounded', [
    'packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf',
  ]);
  final sdk = Platform.environment['FLUTTER_ROOT'];
  if (sdk != null) {
    final f = File('$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (f.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      await loader.load();
    }
  }
}

/// The 390×844 device from the mocks, with a 50pt status bar and a 34pt
/// home indicator.
const kPhone = Size(390, 844);

/// Pump [child] as a full app screen in light or dark.
Future<void> pumpPhone(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  List overrides = const [],
  double pixelRatio = 2,
  Size size = kPhone,
}) async {
  tester.view.physicalSize = size * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  tester.view.padding = FakeViewPadding(top: 50 * pixelRatio, bottom: 34 * pixelRatio);
  tester.view.viewPadding = FakeViewPadding(top: 50 * pixelRatio, bottom: 34 * pixelRatio);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: child,
      ),
    ),
  );
}

/// Let entry animations settle without waiting on ambient loops forever.
Future<void> settle(WidgetTester tester, [Duration d = const Duration(seconds: 2)]) async {
  for (var i = 0; i < d.inMilliseconds ~/ 50; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
