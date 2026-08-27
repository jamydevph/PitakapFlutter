import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract interface class ReminderLocalDatasource {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    String? payload,
  });

  Future<void> cancelReminder(int id);

  Future<void> cancelAll();

  Future<List<int>> pendingReminderIds();
}

class ReminderLocalDatasourceImpl implements ReminderLocalDatasource {
  final FlutterLocalNotificationsPlugin plugin;

  ReminderLocalDatasourceImpl(this.plugin);

  static const String channelId = 'pitakap_reminders';
  static const String channelName = 'Subscription reminders';
  static const String channelDescription =
      'Reminders before a subscription renews';
  static const String androidIcon = '@mipmap/ic_launcher';

  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize() async {
    if (_ready) return;

    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.local);

      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(androidIcon),
          iOS: DarwinInitializationSettings(),
        ),
      );

      _ready = true;
    } catch (error) {
      throw _mapped(error, Strings.reminderInitFailed);
    }
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();

    try {
      final granted = await _android?.requestNotificationsPermission();

      return granted ?? true;
    } catch (error) {
      throw _mapped(error, Strings.reminderPermissionFailed);
    }
  }

  @override
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    String? payload,
  }) async {
    await initialize();

    try {
      await plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        payload: payload,
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (error) {
      throw _mapped(error, Strings.reminderScheduleFailed);
    }
  }

  @override
  Future<void> cancelReminder(int id) async {
    await initialize();

    try {
      await plugin.cancel(id: id);
    } catch (error) {
      throw _mapped(error, Strings.reminderCancelFailed);
    }
  }

  @override
  Future<void> cancelAll() async {
    await initialize();

    try {
      await plugin.cancelAll();
    } catch (error) {
      throw _mapped(error, Strings.reminderCancelFailed);
    }
  }

  @override
  Future<List<int>> pendingReminderIds() async {
    await initialize();

    try {
      final pending = await plugin.pendingNotificationRequests();

      return pending.map((request) => request.id).toList();
    } catch (error) {
      throw _mapped(error, Strings.reminderPendingFailed);
    }
  }

  Failure _mapped(Object error, String fallback) {
    if (error is Failure) return error;

    return NotificationFailure(fallback);
  }
}
