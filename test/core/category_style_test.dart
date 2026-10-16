import 'package:flutter/widgets.dart' show IconData;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:atlas_flutter_app/shared/widgets/daylight/category_style.dart';

void main() {
  IconData icon(String t, [String c = 'custom']) => CategoryStyle.forItem(title: t, category: c).icon;

  test('titles pick specific icons at word starts', () {
    expect(icon('Plan the week'), Symbols.calendar_month_rounded);
    expect(icon('Rest properly tonight'), Symbols.hotel_rounded);
    expect(icon('Wind down before bed'), Symbols.bedtime_rounded);
    expect(icon('Drink enough water'), Symbols.water_drop_rounded);
    expect(icon('Reply to Sam', 'work'), Symbols.mail_rounded);
  });

  test('substrings inside words do not match', () {
    expect(icon('Find an interesting podcast', 'learning'), Symbols.menu_book_rounded);
    expect(icon('Brunch with friends', 'social'), isNot(Symbols.directions_run_rounded));
  });

  test('booking and appointments are not reading', () {
    expect(icon('Book the dentist', 'health'), Symbols.medical_services_rounded);
    expect(icon('Doctor check-up', 'health'), Symbols.medical_services_rounded);
    expect(icon('Book a table for Friday', 'social'), Symbols.calendar_month_rounded);
    expect(icon('Read a book', 'learning'), Symbols.menu_book_rounded);
    expect(icon('Read 20 pages', 'learning'), Symbols.menu_book_rounded);
  });
}
