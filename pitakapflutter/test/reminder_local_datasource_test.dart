import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/feature/subscription/data/datasources/reminder_local_datasource.dart';

class MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  late MockPlugin plugin;
  late ReminderLocalDatasourceImpl datasource;

  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(FakeInitializationSettings());
    registerFallbackValue(FakeNotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(tz.TZDateTime.utc(2026));
  });

  setUp(() {
    plugin = MockPlugin();
    datasource = ReminderLocalDatasourceImpl(plugin);

    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
        onDidReceiveBackgroundNotificationResponse: any(
          named: 'onDidReceiveBackgroundNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);
  });

  group('initialize', () {
    test('initialises the plugin once, not on every call', () async {
      await datasource.initialize();
      await datasource.initialize();
      await datasource.initialize();

      verify(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).called(1);
    });

    test('⭐ a plugin failure surfaces as NotificationFailure', () async {
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).thenThrow(Exception('platform channel exploded'));

      await expectLater(
        datasource.initialize(),
        throwsA(isA<NotificationFailure>()),
      );
    });

    test('⭐ the raw platform error never reaches the message', () async {
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).thenThrow(Exception('MissingPluginException internals'));

      try {
        await datasource.initialize();
        fail('expected a NotificationFailure');
      } catch (error) {
        expect(error, isA<NotificationFailure>());
        expect(
          (error as NotificationFailure).message,
          isNot(contains('MissingPluginException')),
        );
        expect(error.message, 'Could not set up reminders');
      }
    });
  });

  group('scheduleReminder', () {
    test('passes the id, copy and payload through to the plugin', () async {
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          scheduledDate: any(named: 'scheduledDate'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          notificationDetails: any(named: 'notificationDetails'),
        ),
      ).thenAnswer((_) async {});

      await datasource.scheduleReminder(
        id: 42,
        title: 'Payment due soon',
        body: 'Netflix renews in 3 days',
        fireAt: DateTime(2026, 9, 1, 9),
        payload: 'sub-1',
      );

      final captured = verify(
        () => plugin.zonedSchedule(
          id: captureAny(named: 'id'),
          title: captureAny(named: 'title'),
          body: captureAny(named: 'body'),
          payload: captureAny(named: 'payload'),
          scheduledDate: any(named: 'scheduledDate'),
          androidScheduleMode: captureAny(named: 'androidScheduleMode'),
          notificationDetails: any(named: 'notificationDetails'),
        ),
      ).captured;

      expect(captured[0], 42);
      expect(captured[1], AndroidScheduleMode.inexactAllowWhileIdle);
      expect(captured[2], 'Payment due soon');
      expect(captured[3], 'Netflix renews in 3 days');
      expect(captured[4], 'sub-1');
    });

    test('⭐ uses an inexact schedule mode, so no exact-alarm permission', () async {
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          scheduledDate: any(named: 'scheduledDate'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          notificationDetails: any(named: 'notificationDetails'),
        ),
      ).thenAnswer((_) async {});

      await datasource.scheduleReminder(
        id: 1,
        title: 't',
        body: 'b',
        fireAt: DateTime(2026, 9, 1, 9),
      );

      final mode = verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          scheduledDate: any(named: 'scheduledDate'),
          androidScheduleMode: captureAny(named: 'androidScheduleMode'),
          notificationDetails: any(named: 'notificationDetails'),
        ),
      ).captured.single;

      expect(mode, AndroidScheduleMode.inexactAllowWhileIdle);
    });

    test('a scheduling failure surfaces as NotificationFailure', () async {
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          scheduledDate: any(named: 'scheduledDate'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          notificationDetails: any(named: 'notificationDetails'),
        ),
      ).thenThrow(Exception('no'));

      await expectLater(
        datasource.scheduleReminder(
          id: 1,
          title: 't',
          body: 'b',
          fireAt: DateTime(2026, 9, 1, 9),
        ),
        throwsA(isA<NotificationFailure>()),
      );
    });
  });

  group('cancel', () {
    test('cancels by id', () async {
      when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});

      await datasource.cancelReminder(7);

      verify(() => plugin.cancel(id: 7)).called(1);
    });

    test('cancelAll clears every scheduled reminder', () async {
      when(() => plugin.cancelAll()).thenAnswer((_) async {});

      await datasource.cancelAll();

      verify(() => plugin.cancelAll()).called(1);
    });

    test('a cancel failure surfaces as NotificationFailure', () async {
      when(() => plugin.cancel(id: any(named: 'id'))).thenThrow(Exception('no'));

      await expectLater(
        datasource.cancelReminder(7),
        throwsA(isA<NotificationFailure>()),
      );
    });
  });

  group('onReminderTap', () {
    test('⭐ a tap reports the payload as the subscription id', () {
      final tapped = <String>[];
      datasource.onReminderTap = tapped.add;

      datasource.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'sub-42',
        ),
      );

      expect(tapped, ['sub-42']);
    });

    test('⭐ a null payload is ignored, never routed as an empty id', () {
      final tapped = <String>[];
      datasource.onReminderTap = tapped.add;

      datasource.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
        ),
      );

      expect(tapped, isEmpty);
    });

    test('an empty payload is ignored too', () {
      final tapped = <String>[];
      datasource.onReminderTap = tapped.add;

      datasource.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '',
        ),
      );

      expect(tapped, isEmpty);
    });

    test('⭐ a tap with no handler attached does not throw', () {
      datasource.onReminderTap = null;

      expect(
        () => datasource.handleResponse(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'sub-42',
          ),
        ),
        returnsNormally,
      );
    });
  });

  group('pendingReminderIds', () {
    test('returns just the ids', () async {
      when(() => plugin.pendingNotificationRequests()).thenAnswer(
        (_) async => [
          const PendingNotificationRequest(11, 't', 'b', 'p'),
          const PendingNotificationRequest(22, 't', 'b', 'p'),
        ],
      );

      expect(await datasource.pendingReminderIds(), [11, 22]);
    });

    test('is empty when nothing is scheduled', () async {
      when(
        () => plugin.pendingNotificationRequests(),
      ).thenAnswer((_) async => []);

      expect(await datasource.pendingReminderIds(), isEmpty);
    });
  });
}
