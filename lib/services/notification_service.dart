import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_preferences.dart';
import 'app_preferences_service.dart';
import 'notification_content.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'church_journal_reminders';
  static const _channelName = 'Church Journal Reminders';
  static const _daysAhead = 7;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(settings: initSettings);

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Morning and evening journal and scripture reminders',
            importance: Importance.high,
          ),
        );
        await androidPlugin?.requestNotificationsPermission();
      }

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        await _requestDarwinNotificationPermissions();
      }

      _initialized = true;
    } catch (error) {
      debugPrint('NotificationService init failed: $error');
    }
  }

  Future<void> _requestDarwinNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return;
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> refreshScheduledReminders() async {
    if (!_initialized) await init();
    if (!_initialized) return;

    try {
      await _refreshScheduledReminders();
    } catch (error) {
      debugPrint('NotificationService refresh failed: $error');
    }
  }

  Future<void> _refreshScheduledReminders() async {
    await _plugin.cancelAll();

    final prefs = AppPreferencesService.instance.prefs;
    if (prefs.notificationFrequency == NotificationFrequency.none) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var notificationId = 0;

    for (var dayOffset = 0; dayOffset < _daysAhead; dayOffset++) {
      final day = now.add(Duration(days: dayOffset));

      if (_shouldScheduleMorning(prefs)) {
        final morning = tz.TZDateTime(
          tz.local,
          day.year,
          day.month,
          day.day,
          prefs.morningHour,
          prefs.morningMinute,
        );
        if (morning.isAfter(now)) {
          await _scheduleReminder(
            id: notificationId++,
            scheduledAt: morning,
            isMorning: true,
          );
        }
      }

      if (_shouldScheduleEvening(prefs)) {
        final evening = tz.TZDateTime(
          tz.local,
          day.year,
          day.month,
          day.day,
          prefs.eveningHour,
          prefs.eveningMinute,
        );
        if (evening.isAfter(now)) {
          await _scheduleReminder(
            id: notificationId++,
            scheduledAt: evening,
            isMorning: false,
          );
        }
      }
    }
  }

  bool _shouldScheduleMorning(AppPreferences prefs) {
    return prefs.notificationFrequency == NotificationFrequency.twiceDaily ||
        prefs.notificationFrequency == NotificationFrequency.morningOnly;
  }

  bool _shouldScheduleEvening(AppPreferences prefs) {
    return prefs.notificationFrequency == NotificationFrequency.twiceDaily ||
        prefs.notificationFrequency == NotificationFrequency.eveningOnly;
  }

  Future<void> _scheduleReminder({
    required int id,
    required tz.TZDateTime scheduledAt,
    required bool isMorning,
  }) async {
    final body = NotificationContent.pickBody();
    final title = isMorning ? 'Morning Light' : 'Evening Light';

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Morning and evening journal and scripture reminders',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledAt,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
