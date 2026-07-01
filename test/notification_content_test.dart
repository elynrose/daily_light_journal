import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:church_journal/models/app_preferences.dart';
import 'package:church_journal/models/bible_verse.dart';
import 'package:church_journal/models/entry.dart';
import 'package:church_journal/models/mood_scripture.dart';
import 'package:church_journal/models/notification_payload.dart';
import 'package:church_journal/services/app_preferences_service.dart';
import 'package:church_journal/services/bible_storage.dart';
import 'package:church_journal/services/entry_storage.dart';
import 'package:church_journal/services/mood_storage.dart';
import 'package:church_journal/services/notification_content.dart';
import 'package:church_journal/utils/ink_storage.dart';

void main() {
  late Directory tempDir;
  final storage = EntryStorage.instance;
  final bibleStorage = BibleStorage.instance;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('notification_content_test');
    await EntryStorage.instance.init(hivePath: tempDir.path);
    await AppPreferencesService.instance.init(hivePath: tempDir.path);
    bibleStorage.setVersesForTest([
      const BibleVerse(
        reference: 'John 3:16',
        text: 'For God so loved the world',
      ),
    ]);
    MoodStorage.instance.setScripturesForTest([
      const MoodScripture(
        moodName: 'Thankful',
        emoji: '😊',
        scripture: 'Psalm 100:4',
        scriptureText: 'Enter into his gates with thanksgiving.',
      ),
    ]);
    await AppPreferencesService.instance.updateMoodNotificationsEnabled(false);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('uses bible verse when journal is empty', () {
    final body = NotificationContent.pickBody(random: Random(0));

    expect(body, 'John 3:16\nFor God so loved the world');
  });

  test('uses journal note when bible is empty', () async {
    bibleStorage.setVersesForTest([]);

    final day = DateTime(2024, 3, 15);
    await storage.saveEntry(Entry(
      id: 'quote',
      date: day,
      title: '',
      notes: 'The Lord is my shepherd.',
      category: EntryCategory.quote,
      period: ServicePeriod.pm,
    ));

    final body = NotificationContent.pickBody(random: Random(0));

    expect(body, contains('The Lord is my shepherd.'));
    expect(body, contains('3/15/2024'));
  });

  test('mixes journal notes and bible verses when both exist', () async {
    final day = DateTime(2024, 3, 15);
    await storage.saveEntry(Entry(
      id: 'quote',
      date: day,
      title: '',
      notes: 'The Lord is my shepherd.',
      category: EntryCategory.quote,
      period: ServicePeriod.pm,
    ));

    final bodies = {
      for (var i = 0; i < 20; i++)
        NotificationContent.pickBody(random: Random(i)),
    };

    expect(
      bodies.any((body) => body.contains('The Lord is my shepherd.')),
      isTrue,
    );
    expect(
      bodies.any((body) => body.contains('John 3:16')),
      isTrue,
    );
  });

  test('falls back when journal and bible are empty', () {
    bibleStorage.setVersesForTest([]);

    final body = NotificationContent.pickBody();

    expect(body, NotificationContent.fallbackBody);
  });

  test('skips ink-only notes and uses scripture instead', () async {
    final day = DateTime(2026, 6, 26);
    await storage.saveEntry(Entry(
      id: 'quote',
      date: day,
      title: '',
      notes: '',
      category: EntryCategory.quote,
      period: ServicePeriod.pm,
      notePages: [encodeInkStrokes([])],
    ));

    final reminder = NotificationContent.pickReminder(random: Random(0));

    expect(reminder.body, 'John 3:16\nFor God so loved the world');
    expect(reminder.payload, isNotNull);
  });

  test('uses a single random paragraph from multi-paragraph notes', () async {
    bibleStorage.setVersesForTest([]);

    final day = DateTime(2026, 6, 26);
    await storage.saveEntry(Entry(
      id: 'quote',
      date: day,
      title: '',
      notes: '',
      category: EntryCategory.quote,
      period: ServicePeriod.pm,
      notePages: [
        'First paragraph about grace.\n\nSecond paragraph about peace.',
      ],
    ));

    final reminder = NotificationContent.pickReminder(random: Random(0));

    expect(reminder.body, contains('6/26/2026 · PM'));
    expect(
      reminder.body.contains('First paragraph about grace.') ||
          reminder.body.contains('Second paragraph about peace.'),
      isTrue,
    );
    expect(reminder.body, isNot(contains('[[INK:')));
    expect(reminder.payload, isNotNull);
  });

  test('includes mood scripture when mood notifications are enabled', () async {
    bibleStorage.setVersesForTest([]);
    await AppPreferencesService.instance.updateMoodNotificationsEnabled(true);

    final reminder = NotificationContent.pickReminder(random: Random(0));

    expect(reminder.body, contains('Psalm 100:4'));
    expect(reminder.title, '😊 Thankful');

    final payload = NotificationPayload.decode(reminder.payload);
    expect(payload, isA<MoodNotificationPayload>());
    expect(
      (payload as MoodNotificationPayload).moodName,
      'Thankful',
    );
  });

  test('pickMoodReminder returns mood-only notification', () async {
    await AppPreferencesService.instance.updateMoodNotificationsEnabled(true);

    final reminder = NotificationContent.pickMoodReminder(random: Random(0));

    expect(reminder, isNotNull);
    expect(reminder!.body, contains('Enter into his gates'));
  });
}
