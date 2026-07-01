import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/mood_scripture.dart';

class MoodStorage {
  MoodStorage._();

  static final MoodStorage instance = MoodStorage._();

  static const _assetPath = 'assets/mood_scriptures.json';

  List<MoodScripture> _scriptures = [];
  List<MoodOption> _moods = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<MoodOption> get moods => List.unmodifiable(_moods);

  Future<void> load() async {
    if (_loaded) return;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    _scriptures = decoded
        .map((item) => MoodScripture.fromMap(item as Map<String, dynamic>))
        .where((item) => item.moodName.isNotEmpty && item.scripture.isNotEmpty)
        .toList();

    final moodOrder = <String>[];
    final moodByName = <String, String>{};
    for (final item in _scriptures) {
      if (!moodByName.containsKey(item.moodName)) {
        moodOrder.add(item.moodName);
      }
      moodByName.putIfAbsent(item.moodName, () => item.emoji);
    }

    _moods = moodOrder
        .map((name) => MoodOption(name: name, emoji: moodByName[name] ?? ''))
        .toList();

    _loaded = true;
  }

  @visibleForTesting
  void setScripturesForTest(List<MoodScripture> scriptures) {
    _scriptures = List.from(scriptures);
    final moodOrder = <String>[];
    final moodByName = <String, String>{};
    for (final item in _scriptures) {
      if (!moodByName.containsKey(item.moodName)) {
        moodOrder.add(item.moodName);
      }
      moodByName.putIfAbsent(item.moodName, () => item.emoji);
    }
    _moods = moodOrder
        .map((name) => MoodOption(name: name, emoji: moodByName[name] ?? ''))
        .toList();
    _loaded = true;
  }

  MoodScripture? findForMoodAndReference(String moodName, String reference) {
    final normalized = reference.trim().toLowerCase();
    for (final item in _scriptures) {
      if (item.moodName == moodName &&
          item.scripture.trim().toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }

  MoodScripture? pickRandomForMood(String moodName, {Random? random}) {
    final matches =
        _scriptures.where((item) => item.moodName == moodName).toList();
    if (matches.isEmpty) return null;
    final rng = random ?? Random();
    return matches[rng.nextInt(matches.length)];
  }

  MoodScripture? pickRandom({Random? random}) {
    if (_scriptures.isEmpty) return null;
    final rng = random ?? Random();
    return _scriptures[rng.nextInt(_scriptures.length)];
  }
}
