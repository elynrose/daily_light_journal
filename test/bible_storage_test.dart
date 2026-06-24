import 'package:flutter_test/flutter_test.dart';

import 'package:daily_light_journal/models/bible_verse.dart';
import 'package:daily_light_journal/services/bible_storage.dart';

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
}
