import 'package:flutter_test/flutter_test.dart';

import 'package:church_journal/models/bible_verse.dart';
import 'package:church_journal/services/bible_storage.dart';

void main() {
  test('search filters by reference and text', () {
    final storage = BibleStorage.instance;
    storage.setVersesForTest([
      const BibleVerse(
        reference: 'John 3:16',
        text: 'For God so loved the world',
      ),
      const BibleVerse(
        reference: 'Genesis 1:1',
        text: 'In the beginning',
      ),
    ]);

    expect(storage.search('john 3'), hasLength(1));
    expect(storage.search('john 3').first.reference, 'John 3:16');
    expect(storage.search('beginning'), hasLength(1));
    expect(storage.search(''), hasLength(2));
  });

  test('groups verses by chapter and formats notes text', () {
    final verses = [
      const BibleVerse(reference: 'Genesis 1:1', text: 'First verse'),
      const BibleVerse(reference: 'Genesis 1:2', text: 'Second verse'),
      const BibleVerse(reference: 'Genesis 2:1', text: 'Next chapter'),
    ];

    expect(BibleVerse.chapterKeyFromReference('Genesis 1:1'), 'Genesis 1');
    expect(BibleVerse.chapterKeyFromReference('1 Samuel 2:3'), '1 Samuel 2');

    final grouped = BibleStorage.groupByChapter(verses);
    expect(grouped.keys, ['Genesis 1', 'Genesis 2']);
    expect(grouped['Genesis 1'], hasLength(2));

    final notes = BibleStorage.formatVersesForNotes(grouped['Genesis 1']!);
    expect(
      notes,
      'Genesis 1:1\nFirst verse\n\nGenesis 1:2\nSecond verse',
    );
  });

  test('pickRandomVerse returns a verse from the loaded set', () {
    final storage = BibleStorage.instance;
    storage.setVersesForTest([
      const BibleVerse(reference: 'John 3:16', text: 'For God so loved the world'),
      const BibleVerse(reference: 'Genesis 1:1', text: 'In the beginning'),
    ]);

    final verse = storage.pickRandomVerse();
    expect(['John 3:16', 'Genesis 1:1'], contains(verse?.reference));
  });

  test('parseVerseReference splits book, chapter, and verse', () {
    expect(BibleStorage.parseVerseReference('John 3:16'), ('John', 3, 16));
    expect(
      BibleStorage.parseVerseReference('1 Corinthians 13:4'),
      ('1 Corinthians', 13, 4),
    );
    expect(BibleStorage.parseVerseReference('nonsense'), isNull);
  });

  test('book, chapter, and verse selectors reflect the loaded data', () {
    final storage = BibleStorage.instance;
    storage.setVersesForTest([
      const BibleVerse(reference: 'John 3:16', text: 'For God so loved'),
      const BibleVerse(reference: 'John 3:17', text: 'For God sent not'),
      const BibleVerse(reference: 'John 4:1', text: 'When therefore'),
      const BibleVerse(reference: 'Genesis 1:1', text: 'In the beginning'),
    ]);

    expect(storage.books, ['John', 'Genesis']);
    expect(storage.chaptersForBook('John'), [3, 4]);
    expect(storage.versesForBookChapter('John', 3), [16, 17]);
  });

  test('chapterVersesFrom returns the rest of the chapter from a verse', () {
    final storage = BibleStorage.instance;
    storage.setVersesForTest([
      const BibleVerse(reference: 'John 3:15', text: 'Whosoever believeth'),
      const BibleVerse(reference: 'John 3:16', text: 'For God so loved'),
      const BibleVerse(reference: 'John 3:17', text: 'For God sent not'),
      const BibleVerse(reference: 'John 4:1', text: 'When therefore'),
    ]);

    final verses = storage.chapterVersesFrom('John', 3, 16);
    expect(verses.map((v) => v.reference), ['John 3:16', 'John 3:17']);
  });
}
