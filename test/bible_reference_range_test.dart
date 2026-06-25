import 'package:flutter_test/flutter_test.dart';

import 'package:church_journal/utils/bible_reference_range.dart';

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

  test('parseReferenceRange allows spaces around colon and dash', () {
    final range = parseReferenceRange('1 Peter 1 : 1 - 2');

    expect(range, isNotNull);
    expect(range!.book, '1 Peter');
    expect(range.chapter, 1);
    expect(range.startVerse, 1);
    expect(range.endVerse, 2);
    expect(range.displayReference, '1 Peter 1:1-2');
  });

  test('parseReferenceRange handles numbered-book shorthand', () {
    final range = parseReferenceRange('1 Peter : 1-2');

    expect(range, isNotNull);
    expect(range!.book, '1 Peter');
    expect(range.chapter, 1);
    expect(range.startVerse, 1);
    expect(range.endVerse, 2);
    expect(range.displayReference, '1 Peter 1:1-2');
  });

  test('parseReferenceRange rejects shorthand for unnumbered books', () {
    expect(parseReferenceRange('John : 3-16'), isNull);
  });
}
