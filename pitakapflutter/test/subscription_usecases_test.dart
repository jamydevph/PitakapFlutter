import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/repository/subscription_repository.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/reschedule_all_reminders_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/restore_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/update_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/watch_subscriptions_usecase.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

final netflix = SubscriptionEntity(
  id: 'sub-1',
  userId: 'uid-1',
  name: 'Netflix',
  category: 'entertainment',
  amount: 549,
  firstBillDate: DateTime(2026, 1, 31),
);

void main() {
  late MockSubscriptionRepository repository;

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
    registerFallbackValue(RestoreSubscriptionUseCaseParams(netflix));
  });

  setUp(() => repository = MockSubscriptionRepository());

  group('WatchSubscriptionsUseCase', () {
    test('returns the stream the repository exposes', () {
      when(() => repository.watchSubscriptions(any()))
          .thenAnswer((_) => Stream.value([netflix]));

      final stream = WatchSubscriptionsUseCase(repository).call('uid-1');

      expect(stream, emits([netflix]));
      verify(() => repository.watchSubscriptions('uid-1')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('emits an empty list when the user has no subscriptions', () {
      when(() => repository.watchSubscriptions(any()))
          .thenAnswer((_) => Stream.value(const <SubscriptionEntity>[]));

      expect(WatchSubscriptionsUseCase(repository).call('uid-1'), emits(isEmpty));
    });

    test('lets stream failures propagate', () {
      when(() => repository.watchSubscriptions(any())).thenAnswer(
        (_) => Stream.error(const ServerFailure('Could not load')),
      );

      expect(
        WatchSubscriptionsUseCase(repository).call('uid-1'),
        emitsError(isA<ServerFailure>()),
      );
    });
  });

  group('CreateSubscriptionUseCase', () {
    final params = CreateSubscriptionUseCaseParams(
      userId: 'uid-1',
      name: 'Netflix',
      category: 'entertainment',
      amount: 549,
      billingCycle: BillingCycle.monthly,
      firstBillDate: DateTime(2026, 1, 31),
    );

    test('delegates to the repository', () async {
      when(() => repository.createSubscription(any())).thenAnswer((_) async {});

      await CreateSubscriptionUseCase(repository).call(params);

      verify(() => repository.createSubscription(params)).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('carries every field the form collected', () async {
      when(() => repository.createSubscription(any())).thenAnswer((_) async {});

      await CreateSubscriptionUseCase(repository).call(params);

      final captured =
          verify(() => repository.createSubscription(captureAny()))
              .captured
              .single as CreateSubscriptionUseCaseParams;

      expect(captured.userId, 'uid-1');
      expect(captured.name, 'Netflix');
      expect(captured.category, 'entertainment');
      expect(captured.amount, 549);
      expect(captured.billingCycle, BillingCycle.monthly);
      expect(captured.firstBillDate, DateTime(2026, 1, 31));
    });

    test('lets failures propagate', () {
      when(() => repository.createSubscription(any()))
          .thenThrow(const NetworkFailure('No internet connection'));

      expect(
        () => CreateSubscriptionUseCase(repository).call(params),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('UpdateSubscriptionUseCase', () {
    final params = UpdateSubscriptionUseCaseParams(netflix);

    test('delegates to the repository with the edited entity', () async {
      when(() => repository.updateSubscription(any())).thenAnswer((_) async {});

      await UpdateSubscriptionUseCase(repository).call(params);

      final captured =
          verify(() => repository.updateSubscription(captureAny()))
              .captured
              .single as UpdateSubscriptionUseCaseParams;

      expect(captured.subscription, netflix);
      verifyNoMoreInteractions(repository);
    });

    test('lets failures propagate', () {
      when(() => repository.updateSubscription(any()))
          .thenThrow(const ServerFailure('Could not save changes'));

      expect(
        () => UpdateSubscriptionUseCase(repository).call(params),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('DeleteSubscriptionUseCase', () {
    const params = DeleteSubscriptionUseCaseParams('sub-1');

    test('delegates to the repository with the id only', () async {
      when(() => repository.deleteSubscription(any())).thenAnswer((_) async {});

      await DeleteSubscriptionUseCase(repository).call(params);

      final captured =
          verify(() => repository.deleteSubscription(captureAny()))
              .captured
              .single as DeleteSubscriptionUseCaseParams;

      expect(captured.subscriptionId, 'sub-1');
      verifyNoMoreInteractions(repository);
    });

    test('lets failures propagate', () {
      when(() => repository.deleteSubscription(any()))
          .thenThrow(const UnknownFailure('boom'));

      expect(
        () => DeleteSubscriptionUseCase(repository).call(params),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });

  group('RestoreSubscriptionUseCase', () {
    final params = RestoreSubscriptionUseCaseParams(netflix);

    test('delegates to the repository with the whole entity', () async {
      when(() => repository.restoreSubscription(any())).thenAnswer((_) async {});

      await RestoreSubscriptionUseCase(repository).call(params);

      verify(() => repository.restoreSubscription(params)).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('⭐ restore is NOT create — the document id must be carried', () async {
      when(() => repository.restoreSubscription(any())).thenAnswer((_) async {});

      await RestoreSubscriptionUseCase(repository).call(params);

      final captured = verify(
        () => repository.restoreSubscription(captureAny()),
      ).captured.single as RestoreSubscriptionUseCaseParams;

      expect(captured.subscription.id, 'sub-1');
      verifyNever(() => repository.createSubscription(any()));
    });

    test('⭐ every field survives the round trip, not just the id', () async {
      when(() => repository.restoreSubscription(any())).thenAnswer((_) async {});

      await RestoreSubscriptionUseCase(repository).call(params);

      final restored = (verify(
        () => repository.restoreSubscription(captureAny()),
      ).captured.single as RestoreSubscriptionUseCaseParams).subscription;

      expect(restored.userId, 'uid-1');
      expect(restored.name, 'Netflix');
      expect(restored.category, 'entertainment');
      expect(restored.amount, 549);
      expect(restored.billingCycle, BillingCycle.monthly);
      expect(restored.firstBillDate, DateTime(2026, 1, 31));
    });

    test('lets failures propagate', () {
      when(() => repository.restoreSubscription(any()))
          .thenThrow(const NetworkFailure('No internet connection'));

      expect(
        () => RestoreSubscriptionUseCase(repository).call(params),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('RescheduleAllRemindersUseCase', () {
    test('delegates to the repository with the uid', () async {
      when(
        () => repository.rescheduleAllReminders(any()),
      ).thenAnswer((_) async {});

      await RescheduleAllRemindersUseCase(repository).call('uid-1');

      verify(() => repository.rescheduleAllReminders('uid-1')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('⭐ it does not read the subscription stream itself', () async {
      when(
        () => repository.rescheduleAllReminders(any()),
      ).thenAnswer((_) async {});

      await RescheduleAllRemindersUseCase(repository).call('uid-1');

      verifyNever(() => repository.watchSubscriptions(any()));
    });

    test('a read failure propagates — the data half is not optional', () {
      when(() => repository.rescheduleAllReminders(any()))
          .thenThrow(const NetworkFailure('No internet connection'));

      expect(
        () => RescheduleAllRemindersUseCase(repository).call('uid-1'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
