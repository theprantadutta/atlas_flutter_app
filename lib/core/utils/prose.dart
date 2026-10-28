/// House style for prose Atlas did not write itself.
///
/// Atlas never shows em or en dashes: they read as machine-written and the
/// app's voice is meant to sound like a person. Our own copy simply avoids
/// them, but Aurora's replies come from a language model, and a system-prompt
/// instruction is a request rather than a guarantee. Everything the model
/// returns is passed through [stripLongDashes] at the API boundary so a stray
/// dash can never reach the screen or the local database.
library;

/// A dash used as a bullet or opener at the start of a line.
final _leadingDash = RegExp(r'^[ \t]*[—–]+[ \t]*', multiLine: true);

/// A dash following punctuation that already closed the thought. Adding a
/// comma here would stack punctuation, so the dash simply goes away.
final _dashAfterStop = RegExp(r'(?<=[.!?;:,])[ \t]*[—–]+[ \t]*');

/// A dash with air on at least one side, standing in for a comma. Only spaces
/// and tabs are absorbed, so paragraph breaks in Aurora's markdown survive.
final _spacedDash = RegExp(r'[ \t]+[—–]+[ \t]*|[—–]+[ \t]+');

/// A dash wedged between two non-space characters, as in "120–180" or a
/// hyphenated compound. These stay a dash, just the plain ASCII one.
final _tightDash = RegExp(r'(?<=\S)[—–]+(?=\S)');

/// Tidy-ups for whatever the substitution above leaves behind: commas doubled
/// up, pushed against punctuation the model had already written, or stranded
/// at the end of a line.
final _doubledComma = RegExp(r',(?:[ \t]*,)+');
final _spaceBeforeComma = RegExp(r'[ \t]+,');
final _commaBeforeStop = RegExp(r',[ \t]*([.!?;:)\]])');
final _trailingComma = RegExp(r',[ \t]*$', multiLine: true);
final _trailingSpace = RegExp(r'[ \t]+$', multiLine: true);

/// Rewrites em and en dashes as ordinary punctuation, leaving the rest of the
/// text (including markdown structure) untouched.
///
/// ```dart
/// stripLongDashes('Nice work — keep going.'); // 'Nice work, keep going.'
/// stripLongDashes('120–180 words');           // '120-180 words'
/// ```
String stripLongDashes(String input) {
  if (input.isEmpty) return input;
  if (!input.contains('—') && !input.contains('–')) return input;

  // Order matters: a dash that opens a line or follows a full stop is handled
  // before the general "dash means comma" rule gets to it.
  return input
      .replaceAll(_leadingDash, '')
      .replaceAll(_dashAfterStop, ' ')
      .replaceAll(_spacedDash, ', ')
      .replaceAll(_tightDash, '-')
      .replaceAll(_doubledComma, ',')
      .replaceAll(_spaceBeforeComma, ',')
      .replaceAllMapped(_commaBeforeStop, (m) => m[1]!)
      .replaceAll(_trailingComma, '')
      .replaceAll(_trailingSpace, '')
      .trim();
}

/// Markdown to plain prose for headlines, previews and text-to-speech:
/// heading lines are dropped (they label the letter rather than say
/// anything), emphasis markers, links and list bullets are removed, and line
/// breaks collapse to spaces.
String plainText(String markdown) {
  return markdown
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'^\s{0,3}#{1,6}.*$', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*(?:[-*+•]|\d+[.)])\s+', multiLine: true), '')
      .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1]!)
      .replaceAll(RegExp(r'[*_`>]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Splits prose into sentences, keeping the closing punctuation. Abbreviations
/// like "e.g." and decimals stay intact because a split needs a following
/// space and capital (or quote).
List<String> sentences(String text) {
  final t = plainText(_withoutSalutation(text));
  if (t.isEmpty) return const [];
  final out = <String>[];
  final re = RegExp(r'''(?<=[.!?…])["'”’)]?\s+(?=["'“‘(]?[A-Z0-9])''');
  var start = 0;
  for (final m in re.allMatches(t)) {
    final s = t.substring(start, m.start).trim();
    if (s.isNotEmpty) out.add(s);
    start = m.end;
  }
  final rest = t.substring(start).trim();
  if (rest.isNotEmpty) out.add(rest);
  // Glue short fragments ("You didn't vanish.") onto the next sentence, so
  // a headline reads as a thought rather than a word or two.
  final merged = <String>[];
  for (final s in out) {
    if (merged.isNotEmpty && merged.last.split(' ').length < 5) {
      merged[merged.length - 1] = '${merged.last} $s';
    } else {
      merged.add(s);
    }
  }
  return merged;
}

/// A letter's opening line on its own ("Dear you,", "Hi Sam,") is an
/// address, not a thought: left in, it runs into the first sentence and the
/// headline reads "Dear you, Before anything else...". The body still shows it.
final _salutation =
    RegExp(r'^\s*(?:dear|hi|hello|hey)\b[^\n.!?]{0,40},[ \t]*\n', caseSensitive: false);

String _withoutSalutation(String text) => text.replaceFirst(_salutation, '');

/// The first sentence (a letter's headline).
String firstSentence(String text) {
  final s = sentences(text);
  return s.isEmpty ? '' : s.first;
}

/// Up to [n] sentences after the first, cut cleanly at sentence boundaries.
String nextSentences(String text, int n) => sentences(text).skip(1).take(n).join(' ');

/// Reading time at 160 words a minute, at least one minute.
int listenMinutes(String text) {
  final words = plainText(text).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  return (words / 160).ceil().clamp(1, 60);
}
