class BibleReferenceRange {
  final String book;
  final int chapter;
  final int startVerse;
  final int endChapter;
  final int endVerse;

  const BibleReferenceRange({
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
  });

  String verseReference(int verse) => '$book $chapter:$verse';

  String get displayReference {
    if (endChapter == chapter) {
      return '$book $chapter:$startVerse-$endVerse';
    }
    return '$book $chapter:$startVerse-$endChapter:$endVerse';
  }
}

final _numberedBookPattern = RegExp(r'^\d+\s');

BibleReferenceRange? parseReferenceRange(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  final standard = RegExp(
    r'^(.*?)\s+(\d+)\s*:\s*(\d+)\s*-\s*(?:(\d+)\s*:\s*)?(\d+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);

  if (standard != null) {
    return _buildRange(
      book: standard.group(1)!.trim(),
      chapter: int.parse(standard.group(2)!),
      startVerse: int.parse(standard.group(3)!),
      endChapter: standard.group(4) != null
          ? int.parse(standard.group(4)!)
          : int.parse(standard.group(2)!),
      endVerse: int.parse(standard.group(5)!),
    );
  }

  // Numbered books only: "1 Peter : 1-2" → chapter 1, verses 1–2.
  final shorthand = RegExp(
    r'^(.*?)\s*:\s*(\d+)\s*-\s*(\d+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);

  if (shorthand != null) {
    final book = shorthand.group(1)!.trim();
    if (!_numberedBookPattern.hasMatch(book)) return null;

    final chapter = int.parse(shorthand.group(2)!);
    return _buildRange(
      book: book,
      chapter: chapter,
      startVerse: chapter,
      endChapter: chapter,
      endVerse: int.parse(shorthand.group(3)!),
    );
  }

  return null;
}

BibleReferenceRange? _buildRange({
  required String book,
  required int chapter,
  required int startVerse,
  required int endChapter,
  required int endVerse,
}) {
  if (startVerse < 1 || endVerse < 1) return null;
  if (endChapter < chapter) return null;
  if (endChapter == chapter && endVerse < startVerse) return null;

  return BibleReferenceRange(
    book: book,
    chapter: chapter,
    startVerse: startVerse,
    endChapter: endChapter,
    endVerse: endVerse,
  );
}

bool looksLikeReferenceRange(String text) {
  return parseReferenceRange(text) != null;
}
