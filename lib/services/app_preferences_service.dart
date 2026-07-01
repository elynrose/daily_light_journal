import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_preferences.dart';

class AppPreferencesService extends ChangeNotifier {
  AppPreferencesService._();

  static final AppPreferencesService instance = AppPreferencesService._();

  static const _boxName = 'settings';
  static const _prefsKey = 'app_preferences';

  Box<Map>? _box;
  AppPreferences _prefs = const AppPreferences();

  AppPreferences get prefs => _prefs;

  bool get onboardingComplete => _prefs.onboardingComplete;

  Future<void> init({String? hivePath}) async {
    if (_box != null && _box!.isOpen) return;

    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }

    _box = await Hive.openBox<Map>(_boxName);
    final stored = _box?.get(_prefsKey);
    if (stored != null) {
      _prefs = AppPreferences.fromMap(stored);
    }
  }

  Future<void> _save(AppPreferences prefs) async {
    _prefs = prefs;
    await _box?.put(_prefsKey, prefs.toMap());
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required UserRole userRole,
    required NotificationFrequency notificationFrequency,
    required NotificationSource notificationSource,
    required int morningHour,
    required int morningMinute,
    required int eveningHour,
    required int eveningMinute,
  }) {
    return _save(
      _prefs.copyWith(
        onboardingComplete: true,
        userRole: userRole,
        notificationFrequency: notificationFrequency,
        notificationSource: notificationSource,
        morningHour: morningHour,
        morningMinute: morningMinute,
        eveningHour: eveningHour,
        eveningMinute: eveningMinute,
      ),
    );
  }

  Future<void> updateUserRole(UserRole role) =>
      _save(_prefs.copyWith(userRole: role));

  Future<void> updateNotificationFrequency(NotificationFrequency frequency) =>
      _save(_prefs.copyWith(notificationFrequency: frequency));

  Future<void> updateNotificationSource(NotificationSource source) =>
      _save(_prefs.copyWith(notificationSource: source));

  Future<void> updateMorningTime(int hour, int minute) => _save(
        _prefs.copyWith(morningHour: hour, morningMinute: minute),
      );

  Future<void> updateEveningTime(int hour, int minute) => _save(
        _prefs.copyWith(eveningHour: hour, eveningMinute: minute),
      );

  Future<void> updateBibleFontScale(double scale) =>
      _save(_prefs.copyWith(bibleFontScale: scale));

  Future<void> updateNotesFontScale(double scale) =>
      _save(_prefs.copyWith(notesFontScale: scale));

  Future<void> updateLyricsFontScale(double scale) =>
      _save(_prefs.copyWith(lyricsFontScale: scale));

  Future<void> updatePodcastFeedUrls(List<String> urls) {
    final normalized = <String>[];
    final seen = <String>{};
    for (final raw in urls) {
      final url = raw.trim();
      if (url.isEmpty || seen.contains(url)) continue;
      seen.add(url);
      normalized.add(url);
    }
    return _save(_prefs.copyWith(podcastFeedUrls: normalized));
  }

  Future<void> addPodcastFeedUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || _prefs.podcastFeedUrls.contains(trimmed)) {
      return Future.value();
    }
    return updatePodcastFeedUrls([..._prefs.podcastFeedUrls, trimmed]);
  }

  Future<void> removePodcastFeedUrl(String url) =>
      updatePodcastFeedUrls(
        _prefs.podcastFeedUrls.where((entry) => entry != url).toList(),
      );

  Future<void> updateMoodNotificationsEnabled(bool enabled) =>
      _save(_prefs.copyWith(moodNotificationsEnabled: enabled));

  Future<void> updateSelectedMoodName(String moodName) =>
      _save(_prefs.copyWith(selectedMoodName: moodName.trim()));
}
