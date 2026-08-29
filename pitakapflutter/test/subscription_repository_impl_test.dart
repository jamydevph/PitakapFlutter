import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/feature/subscription/data/datasources/reminder_local_datasource.dart';
import 'package:pitakapflutter/feature/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:pitakapflutter/feature/subscription/data/model/subscription_model.dart';
import 'package:pitakapflutter/feature/subscription/data/repository/subscription_repository_impl.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/reminder_schedule.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/restore_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/update_subscription_usecase.dart';

class MockSubscriptionRemoteDatasource extends Mock
    implements SubscriptionRemoteDatasource {}

class MockReminderLocalDatasource extends Mock
    implements ReminderLocalDatasource {}

final netflix = SubscriptionModel(
  id: 'sub-1',
  userId: 'uid-1',
  name: 'Netflix',
  category: 'entertainment',
  amount: 549,
  firstBillDate: DateTime(2026, 1, 31),
);

final now = DateTime(2026, 8, 1, 10);

void main() {
  late MockSubscriptionRemoteDatasource remote;
  late MockReminderLocalDatasource reminders;
  late SubscriptionRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      CreateSubscriptionUseCaseParams(
        userId: '',
        name: '',
        category: '',
        amount: 0,
        firstBillDate: DateTime(2026, 1, 1),
      ),
    );
    registerFallbackValue(UpdateSubscriptionUseCaseParams(netflix));
    registerFallbackValue(const DeleteSubscriptionUseCaseParams(''));
    registerFallbackValue(netflix as SubscriptionEntity);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    remote = MockSubscriptionRemoteDatasource();
    reminders = MockReminderLocalDatasource();
    repository = SubscriptionRepositoryImpl(
      remote,
      reminders,
      clock: () => now,
    );

    when(
      () => reminders.scheduleReminder(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        fireAt: any(named: 'fireAt'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(() => reminders.cancelReminder(any())).thenAnswer((_) async {});
    when(() => reminders.cancelAll()).thenAnswer((_) async {});
  });

  group('watchSubscriptions', () {
    test('forwards the datasource stream as entities', () {
      when(() => remote.watchSubscriptions(any()))
          .thenAnswer((_) => Stream.value([netflix]));

      expect(repository.watchSubscriptions('uid-1'), emits([netflix]));
      verify(() => remote.watchSubscriptions('uid-1')).called(1);
    });

    test('forwards stream errors without re-wrapping them', () {
      when(() => remote.watchSubscriptions(any())).thenAnswer(
        (_) => Stream.error(const NetworkFailure('No internet connection')),
      );

      expect(
        repository.watchSubscriptions('uid-1'),
        emitsError(isA<NetworkFailure>()),
      );
    });
  });

  group('createSubscription', () {
    final params = CreateSubscriptionUseCaseParams(
      userId: 'uid-1',
      name: 'Netflix',
      category: 'entertainment',
      amount: 549,
      firstBillDate: DateTime(2026, 1, 31),
    );

    test('delegates to the datasource', () async {
      when(() => remote.createSubscription(any())).thenAnswer((_) async => 'new-id');

      await repository.createSubscription(params);

      verify(() => remote.createSubscription(params)).called(1);
      verifyNoMoreInteractions(remote);
    });

    test('⭐ schedules a reminder keyed by the id the write returned', () async {
      when(
        () => remote.createSubscription(any()),
      ).thenAnswer((_) async => 'generated-id');

      await repository.createSubscription(params);

      final id = verify(
        () => reminders.scheduleReminder(
          id: captureAny(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          fireAt: any(named: 'fireAt'),
          payload: any(named: 'payload'),
        ),
      ).captured.single;

      expect(id, reminderIdFor('generated-id'));
    });

    test('⭐ the payload is the document id, so a tap can deep-link', () async {
      when(
        () => remote.createSubscription(any()),
      ).thenAnswer((_) async => 'generated-id');

      await repository.createSubscription(params);

      final payload = verify(
        () => reminders.scheduleReminder(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          fireAt: any(named: 'fireAt'),
          payload: captureAny(named: 'payload'),
        ),
      ).captured.single;

      expect(payload, 'generated-id');
    });

    test('lets mapped failures propagate', () {
      when(() => remote.createSubscription(any()))
          .thenThrow(const ServerFailure('You do not have access to this data'));

      expect(
        () => repository.createSubscription(params),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('⭐ a reminder failure never fails the write', () async {
      when(
        () => remote.createSubscription(any()),
      ).thenAnswer((_) async => 'generated-id');
      when(
        () => reminders.scheduleReminder(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          fireAt: any(named: 'fireAt'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(const NotificationFailure('Could not schedule the reminder'));

      await expectLater(repository.createSubscription(params), completes);
    });
  });

  group('updateSubscription', () {
    final params = UpdateSubscriptionUseCaseParams(netflix);

    test('delegates to the datasource', () async {
      when(() => remote.updateSubscription(any())).thenAnswer((_) async {});

      await repository.updateSubscription(params);

      verify(() => remote.updateSubscription(params)).called(1);
      verifyNoMoreInteractions(remote);
    });

    test('⭐ reschedules against the edited subscription', () async {
      when(() => remote.updateSubscription(any())).thenAnswer((_) async {});

      await repository.updateSubscription(params);

      final captured = verify(
        () => reminders.scheduleReminder(
          id: captureAny(named: 'id'),
          title: captureAny(named: 'title'),
          body: captureAny(named: 'body'),
          fireAt: captureAny(named: 'fireAt'),
          payload: any(named: 'payload'),
        ),
      ).captured;

      expect(captured[0], reminderIdFor('sub-1'));
      expect(captured[1], Strings.reminderTitle);
      expect(captured[2], 'Netflix renews in 3 days');
      expect(captured[3], DateTime(2026, 8, 28, reminderHourOfDay));
    });

    test('⭐ deactivating cancels instead of scheduling', () async {
      when(() => remote.updateSubscription(any())).thenAnswer((_) async {});

      final paused = SubscriptionModel(
        id: 'sub-1',
        userId: 'uid-1',
        name: 'Netflix',
        category: 'entertainment',
        amount: 549,
        firstBillDate: DateTime(2026, 1, 31),
        isActive: false,
      );

      await repository.updateSubscription(
        UpdateSubscriptionUseCaseParams(paused),
      );

      verify(() => reminders.cancelReminder(reminderIdFor('sub-1'))).called(1);
      verifyNever(
        () => reminders.scheduleReminder(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          fireAt: any(named: 'fireAt'),
          payload: any(named: 'payload'),
        ),
      );
    });
  });

  group('deleteSubscription', () {
    const params = DeleteSubscriptionUseCaseParams('sub-1');

    test('delegates to the datasource', () async {
      when(() => remote.deleteSubscription(any())).thenAnswer((_) async {});

      await repository.deleteSubscription(params);

      verify(() => remote.deleteSubscription(params)).called(1);
      verifyNoMoreInteractions(remote);
    });

    test('⭐ cancels the reminder for the deleted id', () async {
      when(() => remote.deleteSubscription(any())).thenAnswer((_) async {});

      await repository.deleteSubscription(params);

      verify(() => reminders.cancelReminder(reminderIdFor('sub-1'))).called(1);
    });

    test('lets mapped failures propagate', () {
      when(() => remote.deleteSubscription(any()))
          .thenThrow(const ServerFailure('That record no longer exists'));

      expect(
        () => repository.deleteSubscription(params),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('⭐ a cancel failure never fails the delete', () async {
      when(() => remote.deleteSubscription(any())).thenAnswer((_) async {});
      when(
        () => reminders.cancelReminder(any()),
      ).thenThrow(const NotificationFailure('Could not cancel the reminder'));

      await expectLater(repository.deleteSubscription(params), completes);
    });
  });

  group('restoreSubscription', () {
    final params = RestoreSubscriptionUseCaseParams(netflix);

    test('⭐ writes back the same document, it does not create a new one', () async {
      when(() => remote.restoreSubscription(any())).thenAnswer((_) async {});

      await repository.restoreSubscription(params);

      final restored = verify(
        () => remote.restoreSubscription(captureAny()),
      ).captured.single as SubscriptionEntity;

      expect(restored.id, 'sub-1');
      verifyNever(() => remote.createSubscription(any()));
    });

    test('⭐ the reminder id survives the undo', () async {
      when(() => remote.restoreSubscription(any())).thenAnswer((_) async {});

      await repository.restoreSubscription(params);

      final id = verify(
        () => reminders.scheduleReminder(
          id: captureAny(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          fireAt: any(named: 'fireAt'),
          payload: any(named: 'payload'),
        ),
      ).captured.single;

      expect(id, reminderIdFor('sub-1'));
    });
  });

  group('rescheduleAllReminders', () {
    test('⭐ clears everything first, then schedules each subscription', () async {
      final spotify = SubscriptionModel(
        id: 'sub-2',
        userId: 'uid-1',
        name: 'Spotify',
        category: 'entertainment',
        amount: 149,
        firstBillDate: DateTime(2026, 1, 10),
      );

      when(
        () => remote.watchSubscriptions(any()),
      ).thenAnswer((_) => Stream.value([netflix, spotify]));

      await repository.rescheduleAllReminders('uid-1');

      verifyInOrder([
        () => reminders.cancelAll(),
        () => reminders.scheduleReminder(
          id: reminderIdFor('sub-1'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          fireAt: any(named: 'fireAt'),
          payload: any(named: 'payload'),
        ),
        () => reminders.scheduleReminder(
          id: reminderIdFor('sub-2'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          fireAt: any(named: 'fireAt'),
          payload: any(named: 'payload'),
        ),
      ]);
    });

    test('⭐ takes only the first snapshot, it does not keep listening', () async {
      var listens = 0;

      when(() => remote.watchSubscriptions(any())).thenAnswer((_) {
        listens++;
        return Stream.value([netflix]);
      });

      await repository.rescheduleAllReminders('uid-1');

      expect(listens, 1);
    });

    test('an inactive subscription is cancelled, not scheduled', () async {
      final paused = SubscriptionModel(
        id: 'sub-3',
        userId: 'uid-1',
        name: 'Paused',
        category: 'other',
        amount: 99,
        firstBillDate: DateTime(2026, 1, 5),
        isActive: false,
      );

      when(
        () => remote.watchSubscriptions(any()),
      ).thenAnswer((_) => Stream.value([paused]));

      await repository.rescheduleAllReminders('uid-1');

      verify(() => reminders.cancelReminder(reminderIdFor('sub-3'))).called(1);
    });

    test('⭐ a notification failure never escapes to the caller', () async {
      when(
        () => remote.watchSubscriptions(any()),
      ).thenAnswer((_) => Stream.value([netflix]));
      when(
        () => reminders.cancelAll(),
      ).thenThrow(const NotificationFailure('Could not set up reminders'));

      await expectLater(repository.rescheduleAllReminders('uid-1'), completes);
    });

    test('a read failure does propagate — that is not the optional part', () {
      when(() => remote.watchSubscriptions(any())).thenAnswer(
        (_) => Stream.error(const NetworkFailure('No internet connection')),
      );

      expect(
        () => repository.rescheduleAllReminders('uid-1'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
