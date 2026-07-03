import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/bible_translation.dart';
import '../models/bible_verse.dart';
import '../utils/bible_reference_range.dart';

class BibleStorage {
  BibleStorage._();

  static final BibleStorage instance = BibleStorage._();

  final Map<String, List<BibleVerse>> _cache = {};

  List<BibleVerse> _verses = [];
  String _currentTranslationId = BibleTranslation.kjv.id;
  bool _loaded = false;
  final Map<String, BibleVerse> _versesByNormalizedReference = {};

  final List<String> _bookOrder = [];
  final Map<String, Map<int, List<int>>> _bookChapterVerses = {};

  bool get isLoaded => _loaded;

  String get currentTranslationId => _currentTranslationId;

  BibleTranslation get currentTranslation =>
      BibleTranslation.fromId(_currentTranslationId);

  List<BibleVerse> get allVerses => List.unmodifiable(_verses);

  Future<void> load({String? translationId}) async {
    final id = BibleTranslation.fromId(
      translationId ?? _currentTranslationId,
    ).id;

    if (!_cache.containsKey(id)) {
      final translation = BibleTranslation.fromId(id);
      final raw = await rootBundle.loadString(translation.assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _cache[id] = decoded.entries
          .map(
            (entry) => BibleVerse(
              reference: entry.key,
              text: entry.value as String? ?? '',
            ),
          )
          .toList();
    }

    _currentTranslationId = id;
    _verses = _cache[id]!;
    _rebuildReferenceIndex();
    _loaded = true;
  }

  static String normalizeReference(String reference) {
    return reference
        .toLowerCase()
        .replaceAll(RegExp(r'\s*:\s*'), ':')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _rebuildReferenceIndex() {
    _versesByNormalizedReference
      ..clear()
      ..addEntries(
        _verses.map(
          (verse) => MapEntry(normalizeReference(verse.reference), verse),
        ),
      );

    _bookOrder.clear();
    _bookChapterVerses.clear();
    for (final verse in _verses) {
      final parsed = parseVerseReference(verse.reference);
      if (parsed == null) continue;
      final (book, chapter, verseNumber) = parsed;
      if (!_bookChapterVerses.containsKey(book)) {
        _bookChapterVerses[book] = {};
        _bookOrder.add(book);
      }
      _bookChapterVerses[book]!.putIfAbsent(chapter, () => []).add(verseNumber);
    }
  }

  /// Parses a reference like "1 John 3:16" into (book, chapter, verse).
  static (String, int, int)? parseVerseReference(String reference) {
    final colon = reference.lastIndexOf(':');
    if (colon <= 0) return null;
    final verse = int.tryParse(reference.substring(colon + 1).trim());
    if (verse == null) return null;
    final left = reference.substring(0, colon).trim();
    final lastSpace = left.lastIndexOf(' ');
    if (lastSpace <= 0) return null;
    final chapter = int.tryParse(left.substring(lastSpace + 1).trim());
    if (chapter == null) return null;
    final book = left.substring(0, lastSpace).trim();
    if (book.isEmpty) return null;
    return (book, chapter, verse);
  }

  List<String> get books => List.unmodifiable(_bookOrder);

  List<int> chaptersForBook(String book) {
    final chapters = _bookChapterVerses[book]?.keys.toList() ?? <int>[];
    chapters.sort();
    return chapters;
  }

  List<int> versesForBookChapter(String book, int chapter) {
    final verses = _bookChapterVerses[book]?[chapter]?.toList() ?? <int>[];
    verses.sort();
    return verses;
  }

  /// Returns every verse in [book] [chapter] whose verse number is greater than
  /// or equal to [fromVerse], preserving chapter order.
  List<BibleVerse> chapterVersesFrom(String book, int chapter, int fromVerse) {
    final result = <BibleVerse>[];
    for (final verseNumber in versesForBookChapter(book, chapter)) {
      if (verseNumber < fromVerse) continue;
      final verse = verseForReference('$book $chapter:$verseNumber');
      if (verse != null) result.add(verse);
    }
    return result;
  }

  BibleVerse? verseForReference(String reference) {
    return _versesByNormalizedReference[normalizeReference(reference)];
  }

  List<BibleVerse> versesForReferenceQuery(String query) {
    final range = parseReferenceRange(query);
    if (range != null) {
      return _versesForRange(range);
    }

    final single = verseForReference(query);
    if (single != null) return [single];
    return const [];
  }

  List<BibleVerse> _versesForRange(BibleReferenceRange range) {
    if (range.endChapter != range.chapter) {
      return const [];
    }

    final from = range.startVerse < range.endVerse
        ? range.startVerse
        : range.endVerse;
    final to = range.startVerse > range.endVerse
        ? range.startVerse
        : range.endVerse;

    final verses = <BibleVerse>[];
    for (var verseNumber = from; verseNumber <= to; verseNumber++) {
      final verse = verseForReference(range.verseReference(verseNumber));
      if (verse != null) {
        verses.add(verse);
      }
    }
    return verses;
  }

  List<BibleVerse> search(String query) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return _verses;

    return _verses.where((verse) {
      return verse.reference.toLowerCase().contains(lower) ||
          verse.text.toLowerCase().contains(lower);
    }).toList();
  }

  List<BibleVerse> versesForChapter(String chapterKey) {
    return _verses.where((verse) => verse.chapterKey == chapterKey).toList();
  }

  static Map<String, List<BibleVerse>> groupByChapter(List<BibleVerse> verses) {
    final grouped = <String, List<BibleVerse>>{};
    for (final verse in verses) {
      grouped.putIfAbsent(verse.chapterKey, () => []).add(verse);
    }
    return grouped;
  }

  static String formatVersesForNotes(List<BibleVerse> verses) {
    return verses.map((verse) => verse.toNotesLine()).join('\n\n');
  }

  BibleVerse? pickRandomVerse({Random? random}) {
    if (_verses.isEmpty) return null;
    final index = (random ?? Random()).nextInt(_verses.length);
    return _verses[index];
  }

  @visibleForTesting
  void setVersesForTest(List<BibleVerse> verses) {
    _verses = List<BibleVerse>.from(verses);
    _rebuildReferenceIndex();
    _loaded = true;
  }
}
