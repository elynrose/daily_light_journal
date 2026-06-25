import 'package:flutter_test/flutter_test.dart';

import 'package:daily_light_journal/utils/bible_reference_range.dart';

void main() {
  test('parseReferenceRange handles same-chapter shorthand', () {
    final range = parseReferenceRange('John 14:12-16');

    expect(range, isNotNull);
    expect(range!.book, 'John');
    expect(range.chapter, 14);
    expect(range.startVerse, 12);
    expect(range.endChapter, 14);
    expect(range.endVerse, 16);
    expect(range.displayReference, 'John 14:12-16');
  });

  test('parseReferenceRange is case-insensitive', () {
    final range = parseReferenceRange('john 14:12-16');

    expect(range?.book, 'john');
    expect(range?.displayReference, 'john 14:12-16');
  });
}
