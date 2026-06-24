import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/bible_verse.dart';

class BibleStorage {
  BibleStorage._();

  static final BibleStorage instance = BibleStorage._();

  static const _assetPath = 'Bible.json';

  List<BibleVerse> _verses = [];
  bool _loaded = false;

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
    _loaded = true;
  }

  List<BibleVerse> search(String query) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return _verses;

    return _verses.where((verse) {
      return verse.reference.toLowerCase().contains(lower) ||
          verse.text.toLowerCase().contains(lower);
    }).toList();
  }

  @visibleForTesting
  void setVersesForTest(List<BibleVerse> verses) {
    _verses = List<BibleVerse>.from(verses);
    _loaded = true;
  }
}
