import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:church_journal/main.dart';
import 'package:church_journal/models/app_preferences.dart';
import 'package:church_journal/services/app_preferences_service.dart';
import 'package:church_journal/services/entry_storage.dart';
import 'package:church_journal/services/photo_storage.dart';
import 'package:church_journal/services/song_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('church_journal_test');
    await EntryStorage.instance.init(hivePath: tempDir.path);
    await SongStorage.instance.init(hivePath: tempDir.path);
    await PhotoStorage.instance.init(hivePath: tempDir.path);
    await AppPreferencesService.instance.init(hivePath: tempDir.path);
    await AppPreferencesService.instance.completeOnboarding(
      userRole: UserRole.laity,
      notificationFrequency: NotificationFrequency.none,
      notificationSource: NotificationSource.both,
      morningHour: 7,
      morningMinute: 0,
      eveningHour: 19,
      eveningMinute: 0,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('App loads journal screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DailyLightJournalApp());
    await tester.pumpAndSettle();

    expect(find.text('Prev'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.textContaining('No songs for this'), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('NOTES'), findsOneWidget);
    expect(find.text('PODCAST'), findsOneWidget);
    expect(find.text('WORSHIP'), findsOneWidget);
    expect(find.text('SONGS'), findsOneWidget);
    expect(find.text('BIBLE'), findsOneWidget);
    expect(find.text('PHOTOS'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });
}
