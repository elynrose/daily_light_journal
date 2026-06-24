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
}
