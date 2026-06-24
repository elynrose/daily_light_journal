enum EntryCategory { song, quote, scripture }

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
  String get tabLabel {
    switch (this) {
      case EntryCategory.song:
        return 'SONGS';
      case EntryCategory.quote:
        return 'QUOTES';
      case EntryCategory.scripture:
        return 'SCRIPT';
    }
  }

  String get listTitle {
    switch (this) {
      case EntryCategory.song:
        return 'Songs';
      case EntryCategory.quote:
        return 'Quotes';
      case EntryCategory.scripture:
        return 'Script';
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
  });

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
    };
  }

  factory Entry.fromMap(Map<dynamic, dynamic> map) {
    final rawItems = map['songItems'];
    final items = rawItems is List
        ? rawItems
            .map((item) => DailySongItem.fromMap(item as Map<dynamic, dynamic>))
            .toList()
        : <DailySongItem>[];

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
    );
  }
}
