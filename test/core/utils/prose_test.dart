import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/utils/prose.dart';

void main() {
  group('stripLongDashes', () {
    test('leaves text without long dashes untouched', () {
      const input = 'A calm week. Nothing to fix here.';
      expect(stripLongDashes(input), input);
      expect(stripLongDashes(''), '');
    });

    test('turns a spaced em dash into a comma', () {
      expect(
        stripLongDashes('Nice work — keep going.'),
        'Nice work, keep going.',
      );
    });

    test('handles an en dash the same way', () {
      expect(
        stripLongDashes('Rest is part of it – always has been.'),
        'Rest is part of it, always has been.',
      );
    });

    test('keeps a tight dash as a plain hyphen', () {
      expect(stripLongDashes('120–180 words'), '120-180 words');
      expect(stripLongDashes('self—care'), 'self-care');
    });

    test('does not leave a comma stacked on other punctuation', () {
      expect(
        stripLongDashes('You showed up. — That counts.'),
        'You showed up. That counts.',
      );
    });

    test('drops a dash that ends a sentence rather than stranding a comma', () {
      expect(stripLongDashes('You did enough today —'), 'You did enough today');
    });

    test('removes a dash used as a bullet without eating the line', () {
      expect(
        stripLongDashes('This week:\n— You rested\n— You began again'),
        'This week:\nYou rested\nYou began again',
      );
    });

    test('preserves paragraph breaks in markdown replies', () {
      expect(
        stripLongDashes('First thought — a good one.\n\nSecond thought.'),
        'First thought, a good one.\n\nSecond thought.',
      );
    });

    test('collapses a run of dashes', () {
      expect(stripLongDashes('Wait ——— what?'), 'Wait, what?');
    });
  });
}
