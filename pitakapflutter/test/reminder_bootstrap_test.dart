import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/app_providers.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/subscription_providers.dart';
import 'package:pitakapflutter/core/router/app_router.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/feature/subscription/data/datasources/reminder_local_datasource.dart';
import 'package:pitakapflutter/main.dart';

import 'helpers.dart';

class RecordingReminderDatasource implements ReminderLocalDatasource {
  final Object? cancelAllError;

  int cancelAllCalls = 0;

  void Function(String subscriptionId)? handler;

  RecordingReminderDatasource({this.cancelAllError});

  @override
  set onReminderTap(void Function(String subscriptionId)? value) {
    handler = value;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    String? payload,
  }) async {}

  @override
  Future<void> cancelReminder(int id) async {}

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    if (cancelAllError != null) throw cancelAllError!;
  }

  @override
  Future<List<int>> pendingReminderIds() async => const [];
}

class RecordingSubscriptionRepository extends EmptySubscriptionRepository {
  final List<String> rescheduledFor = [];
  final Object? error;

  RecordingSubscriptionRepository({this.error});

  @override
  Future<void> rescheduleAllReminders(String userId) async {
    rescheduledFor.add(userId);
    if (error != null) throw error!;
  }
}

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required Stream<String?> authState,
    required RecordingReminderDatasource reminders,
    required RecordingSubscriptionRepository repository,
  }) async {
    SharedPreferences.setMockInitialValues(onboarded);
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authStateProvider.overrideWith((ref) => authState),
        userDetailsProvider.overrideWith((ref, uid) => Stream.value(testUser)),
        reminderLocalDatasourceProvider.overrideWithValue(reminders),
        subscriptionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const PitakapApp()),
    );
    await tester.pumpAndSettle();

    return container;
  }

  testWidgets('⭐ reschedules once the user is known', (tester) async {
    final reminders = RecordingReminderDatasource();
    final repository = RecordingSubscriptionRepository();

    await pump(
      tester,
      authState: Stream.value('uid-1'),
      reminders: reminders,
      repository: repository,
    );

    expect(repository.rescheduledFor, ['uid-1']);
  });

  testWidgets('⭐ does not reschedule for a signed-out session', (tester) async {
    final reminders = RecordingReminderDatasource();
    final repository = RecordingSubscriptionRepository();

    await pump(
      tester,
      authState: Stream.value(null),
      reminders: reminders,
      repository: repository,
    );

    expect(repository.rescheduledFor, isEmpty);
  });

  testWidgets('⭐ signing out clears every scheduled reminder', (tester) async {
    final reminders = RecordingReminderDatasource();
    final repository = RecordingSubscriptionRepository();
    final auth = StreamController<String?>();
    addTearDown(auth.close);

    await pump(
      tester,
      authState: auth.stream,
      reminders: reminders,
      repository: repository,
    );

    auth.add('uid-1');
    await tester.pumpAndSettle();

    auth.add(null);
    await tester.pumpAndSettle();

    expect(repository.rescheduledFor, ['uid-1']);
    expect(reminders.cancelAllCalls, 1);
  });

  testWidgets('⭐ a repeated auth emission does not reschedule twice', (
    tester,
  ) async {
    final reminders = RecordingReminderDatasource();
    final repository = RecordingSubscriptionRepository();
    final auth = StreamController<String?>();
    addTearDown(auth.close);

    await pump(
      tester,
      authState: auth.stream,
      reminders: reminders,
      repository: repository,
    );

    auth.add('uid-1');
    await tester.pumpAndSettle();
    auth.add('uid-1');
    await tester.pumpAndSettle();

    expect(repository.rescheduledFor, ['uid-1']);
  });

  testWidgets('a second account reschedules for itself', (tester) async {
    final reminders = RecordingReminderDatasource();
    final repository = RecordingSubscriptionRepository();
    final auth = StreamController<String?>();
    addTearDown(auth.close);

    await pump(
      tester,
      authState: auth.stream,
      reminders: reminders,
      repository: repository,
    );

    auth.add('uid-1');
    await tester.pumpAndSettle();
    auth.add('uid-2');
    await tester.pumpAndSettle();

    expect(repository.rescheduledFor, ['uid-1', 'uid-2']);
  });

  testWidgets('⭐ a reschedule failure never breaks the app', (tester) async {
    final reminders = RecordingReminderDatasource();
    final repository = RecordingSubscriptionRepository(
      error: const NetworkFailure('No internet connection'),
    );

    await pump(
      tester,
      authState: Stream.value('uid-1'),
      reminders: reminders,
      repository: repository,
    );

    expect(tester.takeException(), isNull);
    expect(repository.rescheduledFor, ['uid-1']);
  });

  testWidgets('⭐ a reminder tap opens that subscription detail page', (
    tester,
  ) async {
    final reminders = RecordingReminderDatasource();
    final repository = RecordingSubscriptionRepository();

    final container = await pump(
      tester,
      authState: Stream.value('uid-1'),
      reminders: reminders,
      repository: repository,
    );

    expect(reminders.handler, isNotNull);

    reminders.handler!('sub-42');
    await tester.pumpAndSettle();

    expect(
      container.read(goRouterProvider).state.matchedLocation,
      AppRoutes.subscriptionDetailPath('sub-42'),
    );
  });

  testWidgets('⭐ an empty payload does not navigate anywhere', (tester) async {
    final reminders = RecordingReminderDatasource();
    final repository = RecordingSubscriptionRepository();

    final container = await pump(
      tester,
      authState: Stream.value('uid-1'),
      reminders: reminders,
      repository: repository,
    );

    final before = container.read(goRouterProvider).state.matchedLocation;

    reminders.handler!('');
    await tester.pumpAndSettle();

    expect(container.read(goRouterProvider).state.matchedLocation, before);
  });
}
