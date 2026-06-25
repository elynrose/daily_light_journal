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

BibleReferenceRange? parseReferenceRange(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  final match = RegExp(
    r'^(.*?)\s+(\d+):(\d+)\s*-\s*(?:(\d+):)?(\d+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);

  if (match == null) return null;

  final book = match.group(1)!.trim();
  final chapter = int.parse(match.group(2)!);
  final startVerse = int.parse(match.group(3)!);
  final explicitEndChapter = match.group(4);
  final endVerse = int.parse(match.group(5)!);
  final endChapter =
      explicitEndChapter != null ? int.parse(explicitEndChapter) : chapter;

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
