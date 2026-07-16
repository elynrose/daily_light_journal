import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/song.dart';
import 'sync_service.dart';

class SongStorage {
  SongStorage._();

  static final SongStorage instance = SongStorage._();

  static const _boxName = 'songs';

  static String get boxName => _boxName;

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
    bool? isUserAdded,
  }) async {
    final resolvedId = id ?? const Uuid().v4();
    final existing = id != null ? getSongById(id) : null;
    final resolvedUserAdded = isUserAdded ?? existing?.isUserAdded ?? true;
    final song = Song(
      id: resolvedId,
      title: title.trim(),
      key: key.trim(),
      lyrics: lyrics.trim(),
      number: number.trim(),
      isUserAdded: resolvedUserAdded,
    );
    final map = song.toMap()..['updatedAt'] = SyncService.nowMillis();
    await _box?.put(song.id, map);
    if (song.isUserAdded) {
      SyncService.instance.pushSong(song.id, map);
    }
    return song;
  }

  Future<void> deleteSong(String id) async {
    final existing = getSongById(id);
    await _box?.delete(id);
    if (existing?.isUserAdded ?? false) {
      SyncService.instance.deleteSong(id);
    }
  }

  Future<void> clearAll() async {
    await _box?.clear();
  }

  Future<int> importFromLibraryJson(
    String json, {
    bool replace = false,
  }) async {
    final decoded = jsonDecode(json);
    final List<dynamic> items;
    if (decoded is List<dynamic>) {
      items = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded['songs'] is List<dynamic>) {
      items = decoded['songs'] as List<dynamic>;
    } else {
      throw const FormatException(
        'Song library must be a JSON array or an object with a songs array',
      );
    }

    if (replace) {
      await clearAll();
    }

    var imported = 0;
    for (final item in items) {
      if (item is! Map) continue;
      final song = Song.fromJson(Map<String, dynamic>.from(item));
      if (song.title.trim().isEmpty && song.lyrics.trim().isEmpty) {
        continue;
      }
      await saveSong(
        title: song.title,
        key: song.key,
        lyrics: song.lyrics,
        number: song.number,
        isUserAdded: false,
      );
      imported++;
    }

    if (imported == 0) {
      throw const FormatException('No songs found in library file');
    }

    return imported;
  }

  String exportLibraryJson() {
    final songs = getAllSongs()
        .map(
          (song) => {
            'title': song.title,
            'key': song.key,
            'lyrics': song.lyrics,
            'number': song.number,
          },
        )
        .toList();
    return const JsonEncoder.withIndent('  ').convert(songs);
  }

  Future<void> putRawRecord(String key, Map<String, dynamic> value) async {
    await _box?.put(key, value);
  }

  Map<String, Map<String, dynamic>> exportAllRawRecords() {
    final box = _box;
    if (box == null) return {};
    final records = <String, Map<String, dynamic>>{};
    for (final key in box.keys) {
      final value = box.get(key);
      if (value == null) continue;
      records[key.toString()] = Song.fromMap(value).toMap();
    }
    return records;
  }

  /// Only songs the user created in-app (for cloud sync). Preserves the stored
  /// `updatedAt` field used for last-write-wins conflict resolution.
  Map<String, Map<String, dynamic>> exportUserAddedRawRecords() {
    final box = _box;
    if (box == null) return {};
    final records = <String, Map<String, dynamic>>{};
    for (final key in box.keys) {
      final value = box.get(key);
      if (value == null) continue;
      if (value['isUserAdded'] != true) continue;
      records[key.toString()] = Map<String, dynamic>.from(
        value.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    return records;
  }
}
