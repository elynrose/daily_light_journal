import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/bible_verse.dart';
import '../utils/bible_reference_range.dart';

class BibleStorage {
  BibleStorage._();

  static final BibleStorage instance = BibleStorage._();

  static const _assetPath = 'Bible.json';

  List<BibleVerse> _verses = [];
  bool _loaded = false;
  final Map<String, BibleVerse> _versesByNormalizedReference = {};

  bool get isLoaded => _loaded;

  List<BibleVerse> get allVerses => List.unmodifiable(_verses);

  Future<void> load() async {
    if (_loaded) return;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    _verses = decoded.entries
        .map(
          (entry) => BibleVerse(
            reference: entry.key,
            text: entry.value as String? ?? '',
          ),
        )
        .toList();
    _rebuildReferenceIndex();
    _loaded = true;
  }

  static String normalizeReference(String reference) {
    return reference.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _rebuildReferenceIndex() {
    _versesByNormalizedReference
      ..clear()
      ..addEntries(
        _verses.map(
          (verse) => MapEntry(normalizeReference(verse.reference), verse),
        ),
      );
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
