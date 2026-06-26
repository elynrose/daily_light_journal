import 'dart:math';

import '../models/app_preferences.dart';
import '../models/bible_verse.dart';
import '../models/entry.dart';
import '../models/journal_snippet.dart';
import '../models/notification_payload.dart';
import 'app_preferences_service.dart';
import 'bible_storage.dart';
import 'entry_storage.dart';

class NotificationReminder {
  final String body;
  final String? payload;

  const NotificationReminder({
    required this.body,
    this.payload,
  });
}

class NotificationContent {
  NotificationContent._();

  static const fallbackBody =
      'Add notes to your journal to see them here each morning and evening.';

  static String pickBody({Random? random}) => pickReminder(random: random).body;

  static NotificationReminder pickReminder({Random? random}) {
    final rng = random ?? Random();
    final prefs = AppPreferencesService.instance.prefs;
    final source = prefs.notificationSource;

    final snippet = source == NotificationSource.bible
        ? null
        : EntryStorage.instance.pickRandomJournalSnippet();
    final verse = source == NotificationSource.notes
        ? null
        : BibleStorage.instance.pickRandomVerse(random: rng);

    if (snippet == null && verse == null) {
      return const NotificationReminder(body: fallbackBody);
    }
    if (snippet == null) {
      return _fromVerse(verse!);
    }
    if (verse == null) {
      return _fromSnippet(snippet);
    }

    return rng.nextBool() ? _fromSnippet(snippet) : _fromVerse(verse);
  }

  static NotificationReminder _fromSnippet(JournalSnippet snippet) {
    final category = snippet.category == EntryCategory.song
        ? EntryCategory.quote
        : snippet.category;

    return NotificationReminder(
      body: snippet.toNotificationBody(),
      payload: JournalNotificationPayload(
        date: snippet.date,
        period: snippet.period,
        category: category,
      ).encode(),
    );
  }

  static NotificationReminder _fromVerse(BibleVerse verse) {
    return NotificationReminder(
      body: verse.toNotificationBody(),
      payload: BibleNotificationPayload(reference: verse.reference).encode(),
    );
  }
}
