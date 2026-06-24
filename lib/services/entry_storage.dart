import 'package:hive_flutter/hive_flutter.dart';

import '../models/entry.dart';
import '../models/journal_snippet.dart';
import '../models/song.dart';

class EntryStorage {
  EntryStorage._();

  static final EntryStorage instance = EntryStorage._();

  static const _boxName = 'entries';

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
          e.notes.toLowerCase().contains(lower) ||
          e.songKey.toLowerCase().contains(lower) ||
          e.number.toLowerCase().contains(lower);
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  JournalSnippet? pickRandomJournalSnippet() {
    final withNotes =
        _entries.where((entry) => entry.notes.trim().isNotEmpty).toList();
    if (withNotes.isEmpty) return null;

    withNotes.shuffle();
    final entry = withNotes.first;
    return JournalSnippet(
      date: normalizeDate(entry.date),
      period: entry.period,
      title: getSermonTitleSync(entry.date, period: entry.period),
      preachedBy: getSermonPreachedBySync(entry.date, period: entry.period),
      note: entry.notes.trim(),
    );
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
}
