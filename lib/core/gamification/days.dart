/// Calendar helpers. Atlas thinks in the user's local days: "today" starts at
/// local midnight and weeks start on Monday (ISO 8601).
library;

/// Local midnight of [d].
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// `yyyy-MM-dd` for a local date.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Adds calendar days safely across DST changes (constructs a new local date
/// rather than adding 24h).
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

/// Monday of the ISO week containing [d].
DateTime startOfWeek(DateTime d) => addDays(dateOnly(d), -(d.weekday - 1));

/// The ISO 8601 week number of [d].
int isoWeek(DateTime d) {
  final date = dateOnly(d);
  // Thursday of this week decides the year.
  final thursday = addDays(date, 4 - date.weekday);
  final firstThursday = () {
    final jan4 = DateTime(thursday.year, 1, 4);
    return addDays(jan4, 4 - jan4.weekday);
  }();
  return 1 + (thursday.difference(firstThursday).inDays / 7).round();
}

/// Whole days from [from] to [to] (local dates), DST-safe.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

const _weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December',
];

String weekdayName(DateTime d) => _weekdayNames[d.weekday - 1];
String weekdayLetter(DateTime d) => _weekdayNames[d.weekday - 1][0];
String monthName(DateTime d) => _monthNames[d.month - 1];
String monthShort(DateTime d) => _monthNames[d.month - 1].substring(0, 3);

/// "Tuesday, 14 October"
String longDate(DateTime d) => '${weekdayName(d)}, ${d.day} ${monthName(d)}';

/// "26 Jul to 2 Aug" (house style: no dashes).
String dayRange(DateTime start, DateTime end) {
  final s = '${start.day} ${monthShort(start)}';
  final e = '${end.day} ${monthShort(end)}';
  return '$s to $e';
}

/// "9:00 pm"
String clockLabel(int hour, int minute) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final m = minute.toString().padLeft(2, '0');
  return '$h12:$m ${hour < 12 ? 'am' : 'pm'}';
}

/// Parses "HH:mm" (24h) into (hour, minute), or null.
({int hour, int minute})? parseHm(String? s) {
  if (s == null) return null;
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s.trim());
  if (m == null) return null;
  final h = int.parse(m[1]!);
  final min = int.parse(m[2]!);
  if (h > 23 || min > 59) return null;
  return (hour: h, minute: min);
}

/// "HH:mm" (24h)
String formatHm(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
