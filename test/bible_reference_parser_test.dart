import 'package:flutter_test/flutter_test.dart';

import 'package:church_journal/models/bible_verse.dart';
import 'package:church_journal/services/bible_storage.dart';
import 'package:church_journal/utils/bible_reference_parser.dart';

void main() {
  setUp(() {
    BibleStorage.instance.setVersesForTest([
      const BibleVerse(reference: 'John 3:16', text: 'For God so loved the world'),
      const BibleVerse(reference: 'Genesis 1:1', text: 'In the beginning'),
      const BibleVerse(reference: '1 Samuel 2:3', text: 'Talk no more'),
      const BibleVerse(reference: 'John 14:12', text: 'Verily, verily'),
      const BibleVerse(reference: 'John 14:13', text: 'And whatsoever'),
      const BibleVerse(reference: 'John 14:14', text: 'If ye shall ask'),
      const BibleVerse(reference: 'John 14:15', text: 'If ye love me'),
      const BibleVerse(reference: 'John 14:16', text: 'And I will pray'),
      const BibleVerse(reference: '1 Peter 1:1', text: 'Peter, an apostle'),
      const BibleVerse(reference: '1 Peter 1:2', text: 'Elect according'),
    ]);
  });

  test('verseForReference resolves case-insensitive references', () {
    final storage = BibleStorage.instance;

    expect(storage.verseForReference('john 3:16')?.reference, 'John 3:16');
    expect(storage.verseForReference('1 samuel 2:3')?.reference, '1 Samuel 2:3');
    expect(storage.verseForReference('Unknown 1:1'), isNull);
  });

  test('findReferences links only known verses in text', () {
    const text =
        'Remember John 3:16 today. Also see genesis 1:1 and Fake 9:9.';

    final upper = BibleReferenceParser.findReferences(text);
    expect(upper, hasLength(2));
    expect(upper[0].reference, 'John 3:16');
    expect(upper[0].matchedText, 'John 3:16');
    expect(upper[1].reference, 'Genesis 1:1');
    expect(upper[1].matchedText, 'genesis 1:1');

    const lowerText = 'read john 3:16 and GENESIS 1:1';
    final lower = BibleReferenceParser.findReferences(lowerText);
    expect(lower, hasLength(2));
    expect(lower[0].reference, 'John 3:16');
    expect(lower[0].matchedText, 'john 3:16');
    expect(lower[1].reference, 'Genesis 1:1');
    expect(lower[1].matchedText, 'GENESIS 1:1');
  });

  test('findReferences links scripture ranges like John 14:12-16', () {
    const text = 'Read John 14:12-16 for the promise.';

    final matches = BibleReferenceParser.findReferences(text);

    expect(matches, hasLength(1));
    expect(matches.first.isRange, isTrue);
    expect(matches.first.matchedText, 'John 14:12-16');
    expect(matches.first.reference, 'John 14:12-16');

    final verses = BibleStorage.instance.versesForReferenceQuery('John 14:12-16');
    expect(verses, hasLength(5));
    expect(verses.first.reference, 'John 14:12');
    expect(verses.last.reference, 'John 14:16');
  });

  test('versesForReferenceQuery accepts lowercase ranges', () {
    final verses =
        BibleStorage.instance.versesForReferenceQuery('john 14:12-16');

    expect(verses, hasLength(5));
    expect(verses.map((verse) => verse.reference), [
      'John 14:12',
      'John 14:13',
      'John 14:14',
      'John 14:15',
      'John 14:16',
    ]);
  });

  test('findReferences links 1 Peter : 1-2 shorthand', () {
    const text = 'Meditate on 1 Peter : 1-2 today.';

    final matches = BibleReferenceParser.findReferences(text);

    expect(matches, hasLength(1));
    expect(matches.first.isRange, isTrue);
    expect(matches.first.matchedText, '1 Peter : 1-2');
    expect(matches.first.reference, '1 Peter 1:1-2');

    final verses =
        BibleStorage.instance.versesForReferenceQuery('1 Peter : 1-2');
    expect(verses, hasLength(2));
    expect(verses.first.reference, '1 Peter 1:1');
    expect(verses.last.reference, '1 Peter 1:2');
  });

  test('verseForReference allows spaces around colon', () {
    expect(
      BibleStorage.instance.verseForReference('1 peter 1 : 1')?.reference,
      '1 Peter 1:1',
    );
  });
}
