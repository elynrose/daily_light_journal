import 'app_preferences.dart';

import 'study_audio_attachment.dart';
import '../utils/ink_storage.dart';

enum EntryCategory { song, quote, scripture, feed }

enum ServicePeriod { am, pm }

extension ServicePeriodLabel on ServicePeriod {
  String get label {
    switch (this) {
      case ServicePeriod.am:
        return 'AM';
      case ServicePeriod.pm:
        return 'PM';
    }
  }

  static ServicePeriod fromTime(DateTime time) {
    return time.hour < 12 ? ServicePeriod.am : ServicePeriod.pm;
  }
}

ServicePeriod servicePeriodFromTime(DateTime time) {
  return ServicePeriodLabel.fromTime(time);
}

extension EntryCategoryLabel on EntryCategory {
  static const sideTabOrder = [
    EntryCategory.scripture,
    EntryCategory.song,
    EntryCategory.quote,
    EntryCategory.feed,
  ];

  static List<EntryCategory> sideTabOrderFor(UserRole role) {
    if (role == UserRole.musician) {
      return sideTabOrder;
    }
    return const [
      EntryCategory.scripture,
      EntryCategory.quote,
      EntryCategory.feed,
    ];
  }

  static bool showsWorshipTab(UserRole role) => role == UserRole.musician;

  static bool showsSongsLibraryTab(UserRole role) => role != UserRole.musician;

  static EntryCategory defaultJournalCategory(UserRole role) {
    return role == UserRole.musician
        ? EntryCategory.song
        : EntryCategory.scripture;
  }

  String get tabLabel {
    switch (this) {
      case EntryCategory.song:
        return 'WORSHIP';
      case EntryCategory.quote:
        return 'NOTES';
      case EntryCategory.scripture:
        return 'DEVOTIONAL';
      case EntryCategory.feed:
        return 'PODCAST';
    }
  }

  String get listTitle {
    switch (this) {
      case EntryCategory.song:
        return 'Worship';
      case EntryCategory.quote:
        return 'Notes';
      case EntryCategory.scripture:
        return 'Devotional';
      case EntryCategory.feed:
        return 'Podcast';
    }
  }
}

class DailySongItem {
  final String title;
  final String key;

  const DailySongItem({
    required this.title,
    required this.key,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'key': key,
    };
  }

  factory DailySongItem.fromMap(Map<dynamic, dynamic> map) {
    return DailySongItem(
      title: map['title'] as String? ?? '',
      key: map['key'] as String? ?? '',
    );
  }
}

class Entry {
  final String id;
  final DateTime date;
  final String title;
  final String notes;
  final EntryCategory category;
  final ServicePeriod period;
  final String songKey;
  final String number;
  final List<DailySongItem> songItems;
  final List<String> notePages;
  final String prayerTopics;
  final String gratitude;
  final StudyAudioAttachment? studyAudio;

  Entry({
    required this.id,
    required this.date,
    required this.title,
    required this.notes,
    required this.category,
    this.period = ServicePeriod.am,
    this.songKey = '',
    this.number = '',
    this.songItems = const [],
    this.notePages = const [],
    this.prayerTopics = '',
    this.gratitude = '',
    this.studyAudio,
  });

  List<String> get resolvedNotePages {
    if (notePages.isNotEmpty) return notePages;
    if (notes.trim().isNotEmpty) return [notes];
    return const [];
  }

  String get combinedNotes {
    if (notePages.isNotEmpty) {
      return notePages
          .map(pageText)
          .where((page) => page.trim().isNotEmpty)
          .join('\n\n');
    }
    return notes;
  }

  Entry copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? notes,
    EntryCategory? category,
    ServicePeriod? period,
    String? songKey,
    String? number,
    List<DailySongItem>? songItems,
    List<String>? notePages,
    String? prayerTopics,
    String? gratitude,
    StudyAudioAttachment? studyAudio,
    bool clearStudyAudio = false,
  }) {
    return Entry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      period: period ?? this.period,
      songKey: songKey ?? this.songKey,
      number: number ?? this.number,
      songItems: songItems ?? this.songItems,
      notePages: notePages ?? this.notePages,
      prayerTopics: prayerTopics ?? this.prayerTopics,
      gratitude: gratitude ?? this.gratitude,
      studyAudio: clearStudyAudio ? null : (studyAudio ?? this.studyAudio),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'notes': notes,
      'category': category.index,
      'period': period.index,
      'songKey': songKey,
      'number': number,
      'songItems': songItems.map((item) => item.toMap()).toList(),
      'notePages': notePages,
      'prayerTopics': prayerTopics,
      'gratitude': gratitude,
      if (studyAudio != null) 'studyAudio': studyAudio!.toMap(),
    };
  }

  factory Entry.fromMap(Map<dynamic, dynamic> map) {
    final rawItems = map['songItems'];
    final items = rawItems is List
        ? rawItems
            .map((item) => DailySongItem.fromMap(item as Map<dynamic, dynamic>))
            .toList()
        : <DailySongItem>[];
    final rawPages = map['notePages'];
    final pages = rawPages is List
        ? rawPages.map((page) => page as String? ?? '').toList()
        : <String>[];
    final rawStudyAudio = map['studyAudio'];

    return Entry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      title: map['title'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      category: EntryCategory.values[map['category'] as int],
      period: map['period'] != null
          ? ServicePeriod.values[map['period'] as int]
          : ServicePeriod.am,
      songKey: map['songKey'] as String? ?? '',
      number: map['number'] as String? ?? '',
      songItems: items,
      notePages: pages,
      prayerTopics: map['prayerTopics'] as String? ?? '',
      gratitude: map['gratitude'] as String? ?? '',
      studyAudio: rawStudyAudio is Map
          ? StudyAudioAttachment.fromMap(rawStudyAudio)
          : null,
    );
  }
}
