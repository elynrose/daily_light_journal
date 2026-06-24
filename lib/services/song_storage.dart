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
    if (box == null || box.isNotEmpty) return;

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
