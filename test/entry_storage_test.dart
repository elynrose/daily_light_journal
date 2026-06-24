import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:daily_light_journal/models/entry.dart';
import 'package:daily_light_journal/models/song.dart';
import 'package:daily_light_journal/services/entry_storage.dart';

void main() {
  late Directory tempDir;
  final storage = EntryStorage.instance;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('entry_storage_test');
    await storage.init(hivePath: tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('each date, period, and category pair stores exactly one entry', () async {
    final day = DateTime(2024, 1, 2);

    await storage.saveEntry(Entry(
      id: 'legacy-id',
      date: day,
      title: 'Bring them in',
      notes: 'Verse one',
      category: EntryCategory.song,
      period: ServicePeriod.am,
    ));

    await storage.saveEntry(Entry(
      id: 'another-id',
      date: day,
      title: 'Updated title',
      notes: 'Updated notes',
      category: EntryCategory.song,
      period: ServicePeriod.am,
    ));

    final song = await storage.getEntry(
      day,
      EntryCategory.song,
      period: ServicePeriod.am,
    );
    expect(song?.notes, 'Updated notes');
    expect(
      song?.id,
      EntryStorage.dateCategoryKey(day, EntryCategory.song, period: ServicePeriod.am),
    );

    await storage.saveEntry(Entry(
      id: 'quote-id',
      date: day,
      title: '',
      notes: 'Quote body',
      category: EntryCategory.quote,
      period: ServicePeriod.am,
    ));

    final quote = await storage.getEntry(
      day,
      EntryCategory.quote,
      period: ServicePeriod.am,
    );
    final pmSong = await storage.getEntry(
      day,
      EntryCategory.song,
      period: ServicePeriod.pm,
    );

    expect(quote?.notes, 'Quote body');
    expect(pmSong, isNull);
  });

  test('clearing a slot removes only that date, period, and category', () async {
    final day = DateTime(2024, 1, 2);

    await storage.saveEntry(Entry(
      id: 'x',
      date: day,
      title: '',
      notes: 'Song notes',
      category: EntryCategory.song,
      period: ServicePeriod.am,
    ));
    await storage.saveEntry(Entry(
      id: 'y',
      date: day,
      title: '',
      notes: 'Quote notes',
      category: EntryCategory.quote,
      period: ServicePeriod.am,
    ));

    await storage.deleteEntryForDateCategoryAndPeriod(
      day,
      EntryCategory.song,
      period: ServicePeriod.am,
    );

    expect(
      await storage.getEntry(day, EntryCategory.song, period: ServicePeriod.am),
      isNull,
    );
    expect(
      (await storage.getEntry(day, EntryCategory.quote, period: ServicePeriod.am))
          ?.notes,
      'Quote notes',
    );
  });

  test('addSongToTodayNotes appends list items for the selected period', () async {
    final day = DateTime(2024, 1, 2);

    await storage.addSongToTodayNotes(
      const Song(id: '1', title: 'Bring them in', key: 'C#', lyrics: 'Verse one'),
      date: day,
      period: ServicePeriod.pm,
    );

    final entry = await storage.getEntry(
      day,
      EntryCategory.song,
      period: ServicePeriod.pm,
    );
    expect(entry?.songItems, hasLength(1));
    expect(entry?.songItems.first.title, 'Bring them in');
  });

  test('sermon title is shared per date and period', () async {
    final day = DateTime(2024, 1, 2);

    await storage.setSermonTitle(day, 'Walking by Faith', period: ServicePeriod.am);
    await storage.saveEntry(Entry(
      id: 'quote',
      date: day,
      title: '',
      notes: 'Quote notes',
      category: EntryCategory.quote,
      period: ServicePeriod.am,
    ));

    expect(
      storage.getSermonTitleSync(day, period: ServicePeriod.am),
      'Walking by Faith',
    );

    await storage.saveEntry(Entry(
      id: 'scripture',
      date: day,
      title: '',
      notes: 'Scripture notes',
      category: EntryCategory.scripture,
      period: ServicePeriod.am,
    ));

    expect(
      storage.getSermonTitleSync(day, period: ServicePeriod.am),
      'Walking by Faith',
    );
    expect(
      storage.getSermonTitleSync(day, period: ServicePeriod.pm),
      isEmpty,
    );
  });

  test('preached by is shared per date and period', () async {
    final day = DateTime(2024, 1, 2);

    await storage.setSermonPreachedBy(day, 'Pastor John', period: ServicePeriod.am);
    await storage.saveEntry(Entry(
      id: 'quote',
      date: day,
      title: '',
      notes: 'Quote notes',
      category: EntryCategory.quote,
      period: ServicePeriod.am,
    ));

    expect(
      storage.getSermonPreachedBySync(day, period: ServicePeriod.am),
      'Pastor John',
    );

    await storage.saveEntry(Entry(
      id: 'scripture',
      date: day,
      title: '',
      notes: 'Scripture notes',
      category: EntryCategory.scripture,
      period: ServicePeriod.am,
    ));

    expect(
      storage.getSermonPreachedBySync(day, period: ServicePeriod.am),
      'Pastor John',
    );
    expect(
      storage.getSermonPreachedBySync(day, period: ServicePeriod.pm),
      isEmpty,
    );
  });

  test('pickRandomJournalSnippet returns note with sermon metadata', () async {
    final day = DateTime(2024, 3, 15);

    await storage.setSermonTitle(day, 'Grace Abounds', period: ServicePeriod.pm);
    await storage.setSermonPreachedBy(day, 'Pastor Lee', period: ServicePeriod.pm);
    await storage.saveEntry(Entry(
      id: 'quote',
      date: day,
      title: '',
      notes: 'The Lord is my shepherd.',
      category: EntryCategory.quote,
      period: ServicePeriod.pm,
    ));

    final snippet = storage.pickRandomJournalSnippet();
    expect(snippet, isNotNull);
    expect(snippet!.note, 'The Lord is my shepherd.');
    expect(snippet.title, 'Grace Abounds');
    expect(snippet.preachedBy, 'Pastor Lee');
    expect(snippet.formatDate(), '3/15/2024');
    expect(
      snippet.toNotificationBody(),
      contains('Preached by: Pastor Lee'),
    );
  });

  test('appendScriptureNotes appends text without changing sermon fields', () async {
    final day = EntryStorage.normalizeDate(DateTime.now());

    await storage.setSermonTitle(day, 'Sunday Message', period: ServicePeriod.am);
    await storage.setSermonPreachedBy(day, 'Pastor John', period: ServicePeriod.am);
    await storage.appendScriptureNotes(
      'Genesis 1:1\nIn the beginning',
      date: day,
      period: ServicePeriod.am,
    );
    await storage.appendScriptureNotes(
      'Genesis 1:2\nAnd the earth was without form',
      date: day,
      period: ServicePeriod.am,
    );

    final entry = storage.getEntrySync(
      day,
      EntryCategory.scripture,
      period: ServicePeriod.am,
    );

    expect(entry?.notes, contains('Genesis 1:1'));
    expect(entry?.notes, contains('Genesis 1:2'));
    expect(
      storage.getSermonTitleSync(day, period: ServicePeriod.am),
      'Sunday Message',
    );
    expect(
      storage.getSermonPreachedBySync(day, period: ServicePeriod.am),
      'Pastor John',
    );
  });
}
