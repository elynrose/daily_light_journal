import 'dart:math';

import '../models/app_preferences.dart';
import 'app_preferences_service.dart';
import 'bible_storage.dart';
import 'entry_storage.dart';

class NotificationContent {
  NotificationContent._();

  static const fallbackBody =
      'Add notes to your journal to see them here each morning and evening.';

  static String pickBody({Random? random}) {
    final rng = random ?? Random();
    final prefs = AppPreferencesService.instance.prefs;
    final source = prefs.notificationSource;

    final snippet = source == NotificationSource.bible
        ? null
        : EntryStorage.instance.pickRandomJournalSnippet();
    final verse = source == NotificationSource.notes
        ? null
        : BibleStorage.instance.pickRandomVerse(random: rng);

    if (snippet == null && verse == null) return fallbackBody;
    if (snippet == null) return verse!.toNotificationBody();
    if (verse == null) return snippet.toNotificationBody();

    return rng.nextBool()
        ? snippet.toNotificationBody()
        : verse.toNotificationBody();
  }
}
