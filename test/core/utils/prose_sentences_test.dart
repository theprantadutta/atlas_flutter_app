import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/utils/prose.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';

void main() {
  const letter = '## This week\n\nYou didn\'t vanish. You moved at your own pace. '
      'No failed streaks here, just a pause in a story you\'re still writing. '
      'This week, pick one small kindness to offer yourself. *You* did well.';

  test('splits the headline and the next sentences cleanly', () {
    expect(firstSentence(letter), "You didn't vanish. You moved at your own pace.");
    expect(nextSentences(letter, 1), "No failed streaks here, just a pause in a story you're still writing.");
    expect(nextSentences('One two three four five. Six seven eight nine ten. Eleven twelve thirteen fourteen fifteen. Done.', 2),
        'Six seven eight nine ten. Eleven twelve thirteen fourteen fifteen.');
  });

  test('keeps abbreviations and decimals inside a sentence', () {
    expect(sentences('Try e.g. a short walk today. It was 2.5 km long yesterday.'),
        ['Try e.g. a short walk today.', 'It was 2.5 km long yesterday.']);
  });

  test('plain text drops markdown', () {
    expect(plainText('**Hi** _there_\n- one\n- two'), 'Hi there one two');
    expect(listenMinutes(List.filled(400, 'word').join(' ')), 3);
  });

  group('suggestions', () {
    test('server fields win and exactly one is recommended', () {
      final r = AuroraChatResult.fromJson({
        'reply': 'Pick one?',
        'created': [],
        'is_premium': false,
        'suggestions': [
          {'title': 'A', 'kind': 'habit', 'xp': 15},
          {'title': 'B', 'kind': 'idea', 'xp': 5, 'recommended': true},
        ],
        'follow_ups': ['Plan tomorrow'],
      });
      expect(r.suggestions.map((s) => s.recommended), [false, true]);
      expect(r.suggestions[1].xp, isNull);
      expect(r.followUps, ['Plan tomorrow']);
    });

    test('falls back to a raw block in the reply', () {
      final r = AuroraChatResult.fromJson({
        'reply': 'Hi.\n```suggestions\n{"items":[{"title":"Walk","kind":"task","time":"18:00"}],"followUps":["Why?"]}\n```',
        'created': [],
      });
      expect(r.reply, 'Hi.');
      expect(r.suggestions.single.time, '18:00');
      expect(r.suggestions.single.recommended, isTrue);
      expect(r.followUps, ['Why?']);
    });

    test('falls back to bullets after a question as ideas', () {
      final r = AuroraChatResult.fromJson({
        'reply': 'Maybe something gentler. Pick one?\n- Stretch for 5 minutes\n- A short walk\n- Warm tea',
        'created': [],
      });
      expect(r.reply, 'Maybe something gentler. Pick one?');
      expect(r.suggestions.map((s) => s.kind).toSet(), {'idea'});
      expect(r.suggestions, hasLength(3));
    });

    test('a malformed block is dropped without breaking the reply', () {
      final r = AuroraChatResult.fromJson({'reply': 'Hello\n```suggestions\n{oops\n```', 'created': []});
      expect(r.reply, 'Hello');
      expect(r.suggestions, isEmpty);
    });
  });
}
