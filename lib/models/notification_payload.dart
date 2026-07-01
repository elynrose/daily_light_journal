import 'dart:convert';

import 'entry.dart';

sealed class NotificationPayload {
  const NotificationPayload();

  Map<String, dynamic> toJson();

  String encode() => jsonEncode(toJson());

  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return switch (map['t']) {
        'journal' => JournalNotificationPayload.fromJson(map),
        'bible' => BibleNotificationPayload.fromJson(map),
        'mood' => MoodNotificationPayload.fromJson(map),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}

class JournalNotificationPayload extends NotificationPayload {
  final DateTime date;
  final ServicePeriod period;
  final EntryCategory category;

  const JournalNotificationPayload({
    required this.date,
    required this.period,
    required this.category,
  });

  factory JournalNotificationPayload.fromJson(Map<String, dynamic> map) {
    return JournalNotificationPayload(
      date: DateTime.parse(map['d'] as String),
      period: ServicePeriod.values.firstWhere(
        (value) => value.name == map['p'],
        orElse: () => ServicePeriod.am,
      ),
      category: EntryCategory.values.firstWhere(
        (value) => value.name == map['c'],
        orElse: () => EntryCategory.quote,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        't': 'journal',
        'd': EntryStorageDate.format(date),
        'p': period.name,
        'c': category.name,
      };
}

class BibleNotificationPayload extends NotificationPayload {
  final String reference;

  const BibleNotificationPayload({required this.reference});

  factory BibleNotificationPayload.fromJson(Map<String, dynamic> map) {
    return BibleNotificationPayload(reference: map['r'] as String);
  }

  @override
  Map<String, dynamic> toJson() => {
        't': 'bible',
        'r': reference,
      };
}

class MoodNotificationPayload extends NotificationPayload {
  final String moodName;
  final String scripture;

  const MoodNotificationPayload({
    required this.moodName,
    required this.scripture,
  });

  factory MoodNotificationPayload.fromJson(Map<String, dynamic> map) {
    return MoodNotificationPayload(
      moodName: map['m'] as String? ?? '',
      scripture: map['r'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        't': 'mood',
        'm': moodName,
        'r': scripture,
      };
}

/// Shared date formatting for notification payloads.
class EntryStorageDate {
  EntryStorageDate._();

  static String format(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }
}
