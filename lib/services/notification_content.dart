import 'dart:math';

import 'bible_storage.dart';
import 'entry_storage.dart';

class NotificationContent {
  NotificationContent._();

  static const fallbackBody =
      'Add notes to your journal to see them here each morning and evening.';

  static String pickBody({Random? random}) {
    final rng = random ?? Random();
    final snippet = EntryStorage.instance.pickRandomJournalSnippet();
    final verse = BibleStorage.instance.pickRandomVerse(random: rng);

    if (snippet == null && verse == null) return fallbackBody;
    if (snippet == null) return verse!.toNotificationBody();
    if (verse == null) return snippet.toNotificationBody();

    return rng.nextBool()
        ? snippet.toNotificationBody()
        : verse.toNotificationBody();
  }
}
