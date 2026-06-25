import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/song.dart';

class SongStorage {
  SongStorage._();

  static final SongStorage instance = SongStorage._();

  static const _boxName = 'songs';
  static const _assetPath = 'assets/songs.json';

  Box<Map>? _box;

  Future<void> init({String? hivePath}) async {
    if (_box != null && _box!.isOpen) return;

    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }

    _box = await Hive.openBox<Map>(_boxName);
  }

  Future<void> seedFromAssetIfEmpty() async {
    final box = _box;
    if (box == null) return;

    if (box.isEmpty) {
      await _loadAllSongsFromAsset();
      return;
    }

    await syncMissingSongsFromAsset();
  }

  Future<void> syncMissingSongsFromAsset() async {
    final box = _box;
    if (box == null) return;

    final existingNumbers = getAllSongs()
        .map((song) => song.number)
        .where((number) => number.isNotEmpty)
        .toSet();

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;

    for (final item in decoded) {
      final song = Song.fromJson(item as Map<String, dynamic>);
      if (song.number.isNotEmpty && existingNumbers.contains(song.number)) {
        final existing = getAllSongs().firstWhere(
          (stored) => stored.number == song.number,
        );
        if (_shouldReplaceFromAsset(existing, song)) {
          await box.put(existing.id, song.copyWith(id: existing.id).toMap());
        }
        continue;
      }
      await box.put(song.id, song.toMap());
      if (song.number.isNotEmpty) {
        existingNumbers.add(song.number);
      }
    }
  }

  bool _shouldReplaceFromAsset(Song existing, Song asset) {
    if (existing.lyrics.contains('PP PPaa aagg ggee ee')) {
      return true;
    }
    return _looksLikeSongbookRefTitle(existing.title);
  }

  bool _looksLikeSongbookRefTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^(RH|MP|SP|OB|SK)\b', caseSensitive: false).hasMatch(trimmed);
  }

  Future<void> _loadAllSongsFromAsset() async {
    final box = _box;
    if (box == null) return;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;

    for (final item in decoded) {
      final song = Song.fromJson(item as Map<String, dynamic>);
      await box.put(song.id, song.toMap());
    }
  }

  List<Song> get _songs {
    final box = _box;
    if (box == null) return [];
    return box.values.map(Song.fromMap).toList();
  }

  int _numberSortKey(Song song) {
    return int.tryParse(song.number) ?? 999999;
  }

  List<Song> getAllSongs() {
    return _songs..sort((a, b) => _numberSortKey(a).compareTo(_numberSortKey(b)));
  }

  List<Song> searchSongs(String query) {
    final lower = query.toLowerCase();
    return getAllSongs().where((song) {
      if (lower.isEmpty) return true;
      return song.title.toLowerCase().contains(lower) ||
          song.key.toLowerCase().contains(lower) ||
          song.number.contains(lower) ||
          song.songbookRef.toLowerCase().contains(lower) ||
          song.lyrics.toLowerCase().contains(lower);
    }).toList();
  }

  Song? getSongById(String id) {
    final stored = _box?.get(id);
    if (stored == null) return null;
    return Song.fromMap(stored);
  }

  Song? findSong({required String title, String key = ''}) {
    final normalizedTitle = title.trim().toLowerCase();
    if (normalizedTitle.isEmpty) return null;

    Song? titleMatch;
    for (final song in getAllSongs()) {
      if (song.title.trim().toLowerCase() != normalizedTitle) continue;
      if (key.isNotEmpty && song.key == key) return song;
      titleMatch ??= song;
    }
    return titleMatch;
  }

  Future<Song> saveSong({
    String? id,
    required String title,
    required String key,
    required String lyrics,
    String number = '',
    String songbookRef = '',
  }) async {
    final song = Song(
      id: id ?? const Uuid().v4(),
      title: title.trim(),
      key: key.trim(),
      lyrics: lyrics.trim(),
      number: number.trim(),
      songbookRef: songbookRef.trim(),
    );
    await _box?.put(song.id, song.toMap());
    return song;
  }

  Future<void> deleteSong(String id) async {
    await _box?.delete(id);
  }
}
