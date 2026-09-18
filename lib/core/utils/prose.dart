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
