import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/aurora/screens/aurora_chat_screen.dart';
import 'package:atlas_flutter_app/features/aurora/screens/aurora_screen.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

import '../helpers/golden.dart';

final sampleLetter = AuroraReflection(
  id: 'r1',
  userId: 'u',
  content: "You didn't vanish. You moved at your own pace. No failed streaks here, just a pause "
      "in a story you're still writing. This week, pick one small kindness to offer yourself.\n\n"
      'Your mornings were steady: you moved your body twelve days running.',
  periodStart: DateTime(2025, 7, 26),
  periodEnd: DateTime(2025, 8, 2),
  modelTier: 'paid',
  createdAt: DateTime(2025, 8, 3),
);

class _SampleChat extends AuroraChatNotifier {
  @override
  AuroraChatState build() => const AuroraChatState(messages: [
        ChatMessage(role: ChatRole.user, content: 'I kept my habits this week but I still feel tired'),
        ChatMessage(
          role: ChatRole.aurora,
          content: 'I hear you. Keeping your habits is a quiet kind of strength, even when it '
              "doesn't *feel* like it yet. Maybe your body wants something gentler. Pick one?",
          suggestions: [
            AuroraSuggestion(
                title: '5 min stretch before bed',
                kind: 'habit',
                category: 'mindfulness',
                time: '22:15',
                xp: 15,
                recommended: true),
            AuroraSuggestion(title: 'A short walk outside', kind: 'task', category: 'fitness', xp: 10),
            AuroraSuggestion(title: 'Sit with a warm drink', kind: 'idea'),
          ],
          followUps: ['Plan tomorrow', 'Why am I tired?'],
        ),
      ]);
}

List common() => [
      auroraUsageProvider.overrideWithValue(null),
      onlineProvider.overrideWith((ref) => Stream.value(true)),
    ];

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('aurora $mode', (tester) async {
      await pumpPhone(tester, const AuroraScreen(), dark: dark, overrides: [
        ...common(),
        latestReflectionProvider.overrideWith((ref) => Stream.value(sampleLetter)),
      ]);
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/aurora_$mode.png'));
    });

    testWidgets('aurora chat $mode', (tester) async {
      await pumpPhone(tester, const AuroraChatScreen(), dark: dark, overrides: [
        ...common(),
        auroraChatProvider.overrideWith(_SampleChat.new),
      ]);
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/aurora_chat_$mode.png'));
    });
  }
}
