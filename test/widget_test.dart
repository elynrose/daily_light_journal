import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:daily_light_journal/main.dart';
import 'package:daily_light_journal/services/entry_storage.dart';
import 'package:daily_light_journal/services/song_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('daily_light_journal_test');
    await EntryStorage.instance.init(hivePath: tempDir.path);
    await SongStorage.instance.init(hivePath: tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('App loads journal screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DailyLightJournalApp());

    expect(find.text('Prev'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.textContaining('No songs for this'), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    expect(find.text('NOTES'), findsOneWidget);
    expect(find.text('SONGS'), findsAtLeastNWidgets(1));
    expect(find.text('BIBLE'), findsOneWidget);
  });
}
