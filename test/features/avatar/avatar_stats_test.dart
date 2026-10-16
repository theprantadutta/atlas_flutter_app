import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/avatar/providers/avatar_providers.dart';

void main() {
  LedgerDay day(Map<String, int> cats) => LedgerDay(
        date: DateTime(2025, 1, 1),
        xp: cats.values.fold(0, (a, b) => a + b),
        count: 1,
        items: const {},
        categories: cats,
        types: const {},
      );

  test('stats come from where XP was earned, on a base of 10', () {
    final s = AvatarStats.derive(totalXp: 640, days: [
      day({'fitness': 120, 'health': 30, 'mindfulness': 99}),
      day({'learning': 250, 'custom': 500}),
    ]);
    expect(s.level, LevelInfo.of(640).level);
    expect(s.currentXp, 640);
    expect(s.strength, 13); // 150 / 50
    expect(s.wisdom, 11); // 99 / 50
    expect(s.intelligence, 15); // 250 / 50
  });

  test('matches only when every number is the same', () {
    final s = AvatarStats.derive(totalXp: 0, days: const []);
    final row = Avatar(
      id: 'a',
      userId: 'u',
      name: 'Adventurer',
      level: 1,
      currentXp: 0,
      strength: 10,
      wisdom: 10,
      intelligence: 10,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      isDirty: false,
      isDeleted: false,
    );
    expect(s.matches(row), isTrue);
    expect(s.matches(row.copyWith(wisdom: 11)), isFalse);
  });
}
