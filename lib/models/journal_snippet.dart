import 'dart:math';

import 'entry.dart';
import '../utils/ink_storage.dart';

class JournalSnippet {
  final DateTime date;
  final ServicePeriod period;
  final EntryCategory category;
  final String title;
  final String preachedBy;
  final String note;

  const JournalSnippet({
    required this.date,
    required this.period,
    required this.category,
    required this.title,
    required this.preachedBy,
    required this.note,
  });

  String formatDate() {
    final d = date;
    return '${d.month}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  String toNotificationBody({int maxNoteLength = 220}) {
    final excerpt = _truncate(note, maxNoteLength);
    return '${formatDate()} · ${period.label}\n$excerpt';
  }

  /// Returns a random non-empty paragraph from [text], using the readable text
  /// of a handwriting page and skipping strokes-only pages.
  static String? pickRandomParagraph(String text, {Random? random}) {
    final trimmed = pageText(text).trim();
    if (trimmed.isEmpty) return null;

    final paragraphs = trimmed
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) return null;

    final rng = random ?? Random();
    return paragraphs[rng.nextInt(paragraphs.length)];
  }

  /// Collects readable paragraphs from journal note pages.
  static List<String> collectParagraphs(Iterable<String> pages) {
    final paragraphs = <String>[];
    for (final page in pages) {
      final trimmed = pageText(page).trim();
      if (trimmed.isEmpty) continue;

      final pageParagraphs = trimmed
          .split(RegExp(r'\n\s*\n'))
          .map((paragraph) => paragraph.trim())
          .where((paragraph) => paragraph.isNotEmpty);

      paragraphs.addAll(pageParagraphs);
    }
    return paragraphs;
  }

  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trimRight()}…';
  }
}
