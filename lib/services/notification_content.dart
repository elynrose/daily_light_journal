import 'dart:math';

import '../models/app_preferences.dart';
import '../models/bible_verse.dart';
import '../models/entry.dart';
import '../models/journal_snippet.dart';
import '../models/mood_scripture.dart';
import '../models/notification_payload.dart';
import 'app_preferences_service.dart';
import 'bible_storage.dart';
import 'entry_storage.dart';
import 'mood_storage.dart';

class NotificationReminder {
  final String body;
  final String? payload;
  final String? title;

  const NotificationReminder({
    required this.body,
    this.payload,
    this.title,
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
    final includeMoods = prefs.moodNotificationsEnabled;

    final candidates = <NotificationReminder>[];

    if (source != NotificationSource.bible) {
      final snippet = EntryStorage.instance.pickRandomJournalSnippet(random: rng);
      if (snippet != null) {
        candidates.add(_fromSnippet(snippet));
      }
    }

    if (source != NotificationSource.notes) {
      final verse = BibleStorage.instance.pickRandomVerse(random: rng);
      if (verse != null) {
        candidates.add(_fromVerse(verse));
      }
    }

    if (includeMoods) {
      final moodScripture = _pickMoodScripture(rng, prefs.selectedMoodName);
      if (moodScripture != null) {
        candidates.add(_fromMoodScripture(moodScripture));
      }
    }

    if (candidates.isEmpty) {
      return const NotificationReminder(body: fallbackBody);
    }

    return candidates[rng.nextInt(candidates.length)];
  }

  static NotificationReminder? pickMoodReminder({Random? random}) {
    final rng = random ?? Random();
    final prefs = AppPreferencesService.instance.prefs;
    if (!prefs.moodNotificationsEnabled) return null;

    final moodScripture = _pickMoodScripture(rng, prefs.selectedMoodName);
    if (moodScripture == null) return null;
    return _fromMoodScripture(moodScripture);
  }

  static MoodScripture? _pickMoodScripture(Random rng, String? preferredMood) {
    final storage = MoodStorage.instance;
    if (!storage.isLoaded) return null;

    if (preferredMood != null && preferredMood.trim().isNotEmpty) {
      return storage.pickRandomForMood(preferredMood, random: rng) ??
          storage.pickRandom(random: rng);
    }
    return storage.pickRandom(random: rng);
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

  static NotificationReminder _fromMoodScripture(MoodScripture scripture) {
    return NotificationReminder(
      title: scripture.notificationTitle,
      body: scripture.toNotificationBody(),
      payload: MoodNotificationPayload(
        moodName: scripture.moodName,
        scripture: scripture.scripture,
      ).encode(),
    );
  }
}
