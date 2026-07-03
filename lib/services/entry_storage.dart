import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/entry.dart';
import '../models/journal_snippet.dart';
import '../models/song.dart';

class EntryStorage {
  EntryStorage._();

  static final EntryStorage instance = EntryStorage._();

  static const _boxName = 'entries';

  static String get boxName => _boxName;

  Box<Map>? _box;

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _datePrefix(DateTime date) {
    final d = normalizeDate(date);
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  static String dateCategoryKey(
    DateTime date,
    EntryCategory category, {
    ServicePeriod period = ServicePeriod.am,
  }) {
    return '${_datePrefix(date)}_${period.name}_${category.name}';
  }

  static String sermonTitleKey(
    DateTime date, {
    ServicePeriod period = ServicePeriod.am,
  }) {
    return '${_datePrefix(date)}_${period.name}_sermon_title';
  }

  static String sermonPreachedByKey(
    DateTime date, {
    ServicePeriod period = ServicePeriod.am,
  }) {
    return '${_datePrefix(date)}_${period.name}_sermon_preached_by';
  }

  static bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> init({String? hivePath}) async {
    if (_box != null && _box!.isOpen) return;

    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }

    _box = await Hive.openBox<Map>(_boxName);
    await _migrateLegacyEntries();
  }

  List<Entry> get _entries {
    final box = _box;
    if (box == null) return [];
    return box.values
        .where((map) =>
            map['_type'] != 'sermon_title' &&
            map['_type'] != 'sermon_preached_by')
        .map(Entry.fromMap)
        .toList();
  }

  bool _isLegacyKey(String id) {
    return !id.contains('_am_') &&
        !id.contains('_pm_') &&
        !id.endsWith('_sermon_title') &&
        !id.endsWith('_sermon_preached_by');
  }

  ServicePeriod _legacyPeriodFromId(String id) => ServicePeriod.am;

  EntryCategory? _legacyCategoryFromId(String id) {
    if (id.endsWith('_song')) return EntryCategory.song;
    if (id.endsWith('_quote')) return EntryCategory.quote;
    if (id.endsWith('_scripture')) return EntryCategory.scripture;
    return null;
  }

  Future<void> _migrateLegacyEntries() async {
    for (final entry in List<Entry>.from(_entries)) {
      if (!_isLegacyKey(entry.id)) continue;

      final category = _legacyCategoryFromId(entry.id) ?? entry.category;
      final period = _legacyPeriodFromId(entry.id);
      final key = dateCategoryKey(entry.date, category, period: period);
      final normalized = entry.copyWith(
        id: key,
        date: normalizeDate(entry.date),
        category: category,
        period: period,
      );

      if (entry.id != key) {
        await _box?.delete(entry.id);
      }
      await _box?.put(key, normalized.toMap());

      if (category == EntryCategory.quote || category == EntryCategory.scripture) {
        final existingTitle = getSermonTitleSync(entry.date, period: period);
        if (existingTitle.isEmpty && entry.title.isNotEmpty) {
          await setSermonTitle(entry.date, entry.title, period: period);
        }
      }
    }
  }

  String getSermonTitleSync(
    DateTime date, {
    ServicePeriod period = ServicePeriod.am,
  }) {
    final stored = _box?.get(sermonTitleKey(date, period: period));
    if (stored != null) {
      return stored['title'] as String? ?? '';
    }
    return '';
  }

  Future<void> setSermonTitle(
    DateTime date,
    String title, {
    ServicePeriod period = ServicePeriod.am,
  }) async {
    final key = sermonTitleKey(date, period: period);
    if (title.trim().isEmpty) {
      await _box?.delete(key);
      return;
    }
    await _box?.put(key, {
      '_type': 'sermon_title',
      'title': title.trim(),
    });
  }

  String getSermonPreachedBySync(
    DateTime date, {
    ServicePeriod period = ServicePeriod.am,
  }) {
    final stored = _box?.get(sermonPreachedByKey(date, period: period));
    if (stored != null) {
      return stored['preachedBy'] as String? ?? '';
    }
    return '';
  }

  Future<void> setSermonPreachedBy(
    DateTime date,
    String preachedBy, {
    ServicePeriod period = ServicePeriod.am,
  }) async {
    final key = sermonPreachedByKey(date, period: period);
    if (preachedBy.trim().isEmpty) {
      await _box?.delete(key);
      return;
    }
    await _box?.put(key, {
      '_type': 'sermon_preached_by',
      'preachedBy': preachedBy.trim(),
    });
  }

  Future<void> saveEntry(Entry entry) async {
    final normalizedDate = normalizeDate(entry.date);
    final key = dateCategoryKey(
      normalizedDate,
      entry.category,
      period: entry.period,
    );
    final normalized = entry.copyWith(id: key, date: normalizedDate);

    for (final existing in List<Entry>.from(_entries)) {
      if (existing.id != key &&
          existing.category == normalized.category &&
          existing.period == normalized.period &&
          isSameDate(existing.date, normalizedDate)) {
        await _box?.delete(existing.id);
      }
    }

    await _box?.put(key, normalized.toMap());
  }

  Future<void> deleteEntry(String id) async {
    await _box?.delete(id);
  }

  Future<void> deleteEntryForDateCategoryAndPeriod(
    DateTime date,
    EntryCategory category, {
    ServicePeriod period = ServicePeriod.am,
  }) async {
    final key = dateCategoryKey(date, category, period: period);
    await _box?.delete(key);

    for (final existing in List<Entry>.from(_entries)) {
      if (existing.category == category &&
          existing.period == period &&
          isSameDate(existing.date, date)) {
        await _box?.delete(existing.id);
      }
    }
  }

  Entry? getEntrySync(
    DateTime date,
    EntryCategory category, {
    ServicePeriod period = ServicePeriod.am,
  }) {
    final key = dateCategoryKey(date, category, period: period);
    final stored = _box?.get(key);
    if (stored != null) {
      return Entry.fromMap(stored);
    }

    for (final entry in _entries) {
      if (entry.category == category &&
          entry.period == period &&
          isSameDate(entry.date, date)) {
        return entry;
      }
    }
    return null;
  }

  Future<Entry?> getEntry(
    DateTime date,
    EntryCategory category, {
    ServicePeriod period = ServicePeriod.am,
  }) async {
    return getEntrySync(date, category, period: period);
  }

  @Deprecated('Use getEntrySync')
  Entry? getEntryForDateAndCategorySync(
    DateTime date,
    EntryCategory category,
  ) {
    return getEntrySync(date, category);
  }

  @Deprecated('Use getEntry')
  Future<Entry?> getEntryForDateAndCategory(
    DateTime date,
    EntryCategory category,
  ) async {
    return getEntrySync(date, category);
  }

  Future<List<Entry>> getEntriesByCategory(EntryCategory category) async {
    return _entries.where((e) => e.category == category).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  Future<List<Entry>> searchEntries(String query, EntryCategory category) async {
    final lower = query.toLowerCase();
    return _entries.where((e) {
      if (e.category != category) return false;
      if (lower.isEmpty) return true;
      return e.title.toLowerCase().contains(lower) ||
          e.combinedNotes.toLowerCase().contains(lower) ||
          e.songKey.toLowerCase().contains(lower) ||
          e.number.toLowerCase().contains(lower);
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  JournalSnippet? pickRandomJournalSnippet({Random? random}) {
    final rng = random ?? Random();
    final candidates = <JournalSnippet>[];

    for (final entry in _entries) {
      final paragraphs = JournalSnippet.collectParagraphs(entry.resolvedNotePages);
      if (paragraphs.isEmpty) continue;

      candidates.add(
        JournalSnippet(
          date: normalizeDate(entry.date),
          period: entry.period,
          category: entry.category,
          title: getSermonTitleSync(entry.date, period: entry.period),
          preachedBy: getSermonPreachedBySync(entry.date, period: entry.period),
          note: paragraphs[rng.nextInt(paragraphs.length)],
        ),
      );
    }

    if (candidates.isEmpty) return null;
    return candidates[rng.nextInt(candidates.length)];
  }

  Future<void> appendScriptureNotes(
    String text, {
    DateTime? date,
    ServicePeriod? period,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final targetDate = normalizeDate(date ?? DateTime.now());
    final targetPeriod = period ?? servicePeriodFromTime(DateTime.now());
    final existing = getEntrySync(
      targetDate,
      EntryCategory.scripture,
      period: targetPeriod,
    );
    final existingNotes = existing?.notes.trim() ?? '';
    final notes = existingNotes.isEmpty
        ? trimmed
        : '$existingNotes\n\n$trimmed';

    await saveEntry(Entry(
      id: dateCategoryKey(
        targetDate,
        EntryCategory.scripture,
        period: targetPeriod,
      ),
      date: targetDate,
      title: '',
      notes: notes,
      category: EntryCategory.scripture,
      period: targetPeriod,
      prayerTopics: existing?.prayerTopics ?? '',
      gratitude: existing?.gratitude ?? '',
      studyAudio: existing?.studyAudio,
    ));
  }

  Future<void> addSongToTodayNotes(
    Song song, {
    DateTime? date,
    ServicePeriod? period,
  }) async {
    final targetDate = normalizeDate(date ?? DateTime.now());
    final targetPeriod = period ?? servicePeriodFromTime(DateTime.now());
    final existing = getEntrySync(
      targetDate,
      EntryCategory.song,
      period: targetPeriod,
    );

    final items = List<DailySongItem>.from(existing?.songItems ?? []);
    items.add(DailySongItem(title: song.title, key: song.key));

    await saveEntry(Entry(
      id: dateCategoryKey(targetDate, EntryCategory.song, period: targetPeriod),
      date: targetDate,
      title: '',
      notes: '',
      category: EntryCategory.song,
      period: targetPeriod,
      songItems: items,
    ));
  }

  Future<void> clearAll() async {
    await _box?.clear();
  }

  Future<void> putRawRecord(String key, Map<String, dynamic> value) async {
    await _box?.put(key, value);
  }

  Map<String, Map<String, dynamic>> exportAllRawRecords() {
    final box = _box;
    if (box == null) return {};
    final records = <String, Map<String, dynamic>>{};
    for (final key in box.keys) {
      final value = box.get(key);
      if (value == null) continue;
      records[key.toString()] = _normalizeRawMap(value);
    }
    return records;
  }

  Map<String, dynamic> _normalizeRawMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _normalizeRawMap(value));
      }
      if (value is List) {
        return MapEntry(
          key.toString(),
          value.map((item) {
            if (item is Map) return _normalizeRawMap(item);
            return item;
          }).toList(),
        );
      }
      return MapEntry(key.toString(), value);
    });
  }
}
