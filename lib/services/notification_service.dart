import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'entry_storage.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'daily_light_reminders';
  static const _channelName = 'Daily Light Reminders';
  static const _morningHour = 7;
  static const _eveningHour = 19;
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
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(settings: initSettings);

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Morning and evening journal reminders',
            importance: Importance.high,
          ),
        );
        await androidPlugin?.requestNotificationsPermission();
      }

      _initialized = true;
    } catch (error) {
      debugPrint('NotificationService init failed: $error');
    }
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

    final now = tz.TZDateTime.now(tz.local);
    var notificationId = 0;

    for (var dayOffset = 0; dayOffset < _daysAhead; dayOffset++) {
      final day = now.add(Duration(days: dayOffset));

      final morning = tz.TZDateTime(
        tz.local,
        day.year,
        day.month,
        day.day,
        _morningHour,
      );
      if (morning.isAfter(now)) {
        await _scheduleReminder(
          id: notificationId++,
          scheduledAt: morning,
          isMorning: true,
        );
      }

      final evening = tz.TZDateTime(
        tz.local,
        day.year,
        day.month,
        day.day,
        _eveningHour,
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

  Future<void> _scheduleReminder({
    required int id,
    required tz.TZDateTime scheduledAt,
    required bool isMorning,
  }) async {
    final snippet = EntryStorage.instance.pickRandomJournalSnippet();
    final title = isMorning ? 'Morning Light' : 'Evening Light';
    final body = snippet?.toNotificationBody() ??
        'Add notes to your journal to see them here each morning and evening.';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Morning and evening journal reminders',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledAt,
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
