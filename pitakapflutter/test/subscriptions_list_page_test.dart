import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/repository/subscription_repository.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/restore_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/presentation/widgets/subscription_tile.dart';

import 'helpers.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

SubscriptionEntity sub({
  String id = 'sub-1',
  String name = 'Netflix',
  String category = 'entertainment',
  double amount = 549,
  BillingCycle cycle = BillingCycle.monthly,
  DateTime? firstBillDate,
}) {
  return SubscriptionEntity(
    id: id,
    userId: 'uid-1',
    name: name,
    category: category,
    amount: amount,
    billingCycle: cycle,
    firstBillDate: firstBillDate ?? DateTime(2026, 1, 15),
  );
}

void main() {
  late MockSubscriptionRepository repository;

  setUpAll(() {
    registerAuthFallbacks();
    registerFallbackValue(
      const DeleteSubscriptionUseCaseParams('sub-1'),
    );
    registerFallbackValue(
      CreateSubscriptionUseCaseParams(
        userId: 'uid-1',
        name: '',
        category: '',
        amount: 0,
        firstBillDate: DateTime(2026),
      ),
    );
    registerFallbackValue(RestoreSubscriptionUseCaseParams(sub()));
  });

  setUp(() {
    repository = MockSubscriptionRepository();
    when(() => repository.deleteSubscription(any())).thenAnswer((_) async {});
    when(() => repository.createSubscription(any())).thenAnswer((_) async {});
    when(() => repository.restoreSubscription(any())).thenAnswer((_) async {});
  });

  Future<void> pumpList(
    WidgetTester tester,
    List<SubscriptionEntity> items,
  ) async {
    when(() => repository.watchSubscriptions(any()))
        .thenAnswer((_) => Stream.value(items));

    await pumpAppAt(
      tester,
      AppRoutes.subscriptions,
      signedInUid: 'uid-1',
      subscriptionRepository: repository,
    );
  }

  group('SubscriptionsListPage', () {
    testWidgets('shows an empty state when there is nothing yet', (
      tester,
    ) async {
      await pumpList(tester, const []);

      expect(find.byType(CommonEmptyState), findsOneWidget);
      expect(find.text(Strings.subscriptionsEmptyTitle), findsOneWidget);
      expect(find.byType(SubscriptionTile), findsNothing);
    });

    testWidgets('renders one tile per subscription', (tester) async {
      await pumpList(tester, [
        sub(id: 'a', name: 'Netflix'),
        sub(id: 'b', name: 'Spotify', category: 'entertainment'),
        sub(id: 'c', name: 'PLDT Fibr', category: 'utilities'),
      ]);

      expect(find.byType(SubscriptionTile), findsNWidgets(3));
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('PLDT Fibr'), findsOneWidget);
      expect(find.byType(CommonEmptyState), findsNothing);
    });

    testWidgets('shows the monthly cost so cycles compare fairly', (
      tester,
    ) async {
      await pumpList(tester, [
        sub(name: 'Yearly Thing', amount: 6588, cycle: BillingCycle.yearly),
      ]);

      expect(find.textContaining('549'), findsOneWidget);
      expect(find.textContaining(Strings.perMonthSuffix), findsOneWidget);
    });

    testWidgets('surfaces a load failure instead of an empty list', (
      tester,
    ) async {
      when(() => repository.watchSubscriptions(any())).thenAnswer(
        (_) => Stream.error(const NetworkFailure('No internet connection')),
      );

      await pumpAppAt(
        tester,
        AppRoutes.subscriptions,
        signedInUid: 'uid-1',
        subscriptionRepository: repository,
      );

      expect(find.text(Strings.subscriptionsLoadFailed), findsOneWidget);
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text(Strings.subscriptionsEmptyTitle), findsNothing);
    });
  });

  group('swipe to delete', () {
    testWidgets('deletes the swiped subscription and offers undo', (
      tester,
    ) async {
      await pumpList(tester, [sub(id: 'a', name: 'Netflix')]);

      await tester.drag(
        find.byType(SubscriptionTile),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      final captured = verify(
        () => repository.deleteSubscription(captureAny()),
      ).captured.single as DeleteSubscriptionUseCaseParams;
      expect(captured.subscriptionId, 'a');

      expect(find.text(Strings.undoAction), findsOneWidget);
    });

    testWidgets('⭐ undo restores the same document id, it does not re-create', (
      tester,
    ) async {
      await pumpList(tester, [sub(id: 'a', name: 'Netflix', amount: 549)]);

      await tester.drag(
        find.byType(SubscriptionTile),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(Strings.undoAction));
      await tester.pumpAndSettle();

      final captured = verify(
        () => repository.restoreSubscription(captureAny()),
      ).captured.single as RestoreSubscriptionUseCaseParams;

      expect(captured.subscription.id, 'a');
      expect(captured.subscription.name, 'Netflix');
      expect(captured.subscription.amount, 549);
      expect(captured.subscription.userId, 'uid-1');

      verifyNever(() => repository.createSubscription(any()));
    });

    testWidgets('a failed undo reports the error', (tester) async {
      when(() => repository.restoreSubscription(any()))
          .thenThrow(const NetworkFailure('No internet connection'));

      await pumpList(tester, [sub(id: 'a', name: 'Netflix')]);

      await tester.drag(
        find.byType(SubscriptionTile),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(Strings.undoAction));
      await tester.pumpAndSettle();

      expect(find.text('No internet connection'), findsOneWidget);
    });

    testWidgets('a failed delete reports the error', (tester) async {
      when(() => repository.deleteSubscription(any()))
          .thenThrow(const NetworkFailure('No internet connection'));

      await pumpList(tester, [sub(id: 'a')]);

      await tester.drag(
        find.byType(SubscriptionTile),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text(Strings.undoAction), findsNothing);
    });
  });

  group('SubscriptionTile.dueLabel', () {
    test('reads as words when the date is near', () {
      expect(SubscriptionTile.dueLabel(0, DateTime(2026, 8, 12)),
          Strings.dueToday);
      expect(SubscriptionTile.dueLabel(1, DateTime(2026, 8, 13)),
          Strings.dueTomorrow);
      expect(SubscriptionTile.dueLabel(3, DateTime(2026, 8, 15)), 'in 3 days');
    });

    test('falls back to a calendar date once it is far off', () {
      expect(SubscriptionTile.dueLabel(4, DateTime(2026, 8, 16)), 'Aug 16');
      expect(SubscriptionTile.dueLabel(40, DateTime(2026, 9, 21)), 'Sep 21');
    });

    test('treats an overdue date as due today', () {
      expect(SubscriptionTile.dueLabel(-2, DateTime(2026, 8, 10)),
          Strings.dueToday);
    });
  });
}
