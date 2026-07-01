import 'package:church_journal/models/bible_translation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lists bundled bible translations', () {
    expect(BibleTranslation.all, hasLength(24));
    expect(BibleTranslation.fromId('kjv').label, 'KJV');
    expect(BibleTranslation.fromId('esv').assetPath, 'translations/ESV.json');
    expect(BibleTranslation.fromId('unknown').id, 'kjv');
  });
}
