import 'dart:io';

import 'package:church_journal/services/song_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('church_journal_song_test');
    await SongStorage.instance.init(hivePath: tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('imports and exports song library json', () async {
    const json = '''
[
  {
    "title": "Test Song",
    "key": "C",
    "number": "10",
    "lyrics": "Line one\\nLine two"
  }
]
''';

    final imported = await SongStorage.instance.importFromLibraryJson(json);
    expect(imported, 1);

    final songs = SongStorage.instance.getAllSongs();
    expect(songs, hasLength(1));
    expect(songs.first.title, 'Test Song');
    expect(songs.first.lyrics, 'Line one\nLine two');

    final exported = SongStorage.instance.exportLibraryJson();
    expect(exported, contains('"title": "Test Song"'));
  });
}
