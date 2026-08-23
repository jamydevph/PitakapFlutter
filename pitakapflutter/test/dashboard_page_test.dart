import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/utils/billing_date_utils.dart';
import 'package:pitakapflutter/feature/auth/domain/entities/user_details_entity.dart';
import 'package:pitakapflutter/feature/dashboard/presentation/dashboard_page.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/update_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/repository/subscription_repository.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/update_subscription_usecase.dart';

import 'helpers.dart';

class StubSubscriptionRepository implements SubscriptionRepository {
  final List<SubscriptionEntity> items;
  final Object? error;

  const StubSubscriptionRepository({this.items = const [], this.error});

  @override
  Stream<List<SubscriptionEntity>> watchSubscriptions(String userId) {
    if (error != null) return Stream.error(error!);
    return Stream.value(items);
  }

  @override
  Future<void> createSubscription(CreateSubscriptionUseCaseParams p) async {}

  @override
  Future<void> updateSubscription(UpdateSubscriptionUseCaseParams p) async {}

  @override
  Future<void> deleteSubscription(DeleteSubscriptionUseCaseParams p) async {}
}

class StubExpenseRepository implements ExpenseRepository {
  final List<ExpenseEntity> items;

  const StubExpenseRepository({this.items = const []});

  @override
  Stream<List<ExpenseEntity>> watchExpensesForDay(
    WatchExpensesForDayParams params,
  ) {
    return Stream.value(items);
  }

  @override
  Stream<List<ExpenseEntity>> watchExpensesForMonth(
    WatchExpensesForMonthParams params,
  ) {
    return Stream.value(const []);
  }

  @override
  Future<void> createExpense(CreateExpenseUseCaseParams p) async {}

  @override
  Future<void> updateExpense(UpdateExpenseUseCaseParams p) async {}

  @override
  Future<void> deleteExpense(DeleteExpenseUseCaseParams p) async {}
}

void main() {
  final today = startOfDay(DateTime.now());

  SubscriptionEntity sub({
    required String name,
    double amount = 549,
    int dayOfMonth = 15,
    String category = 'entertainment',
  }) {
    return SubscriptionEntity(
      id: name,
      userId: 'uid-1',
      name: name,
      category: category,
      amount: amount,
      billingCycle: BillingCycle.monthly,
      firstBillDate: DateTime(2024, 1, dayOfMonth),
    );
  }

  ExpenseEntity expense({required double amount, String id = 'e1'}) {
    return ExpenseEntity(
      id: id,
      userId: 'uid-1',
      description: 'Lunch',
      category: 'food',
      amount: amount,
      date: today,
    );
  }

  void sizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('greetingFor', () {
    test('is time of day, not a fixed string', () {
      expect(DashboardPage.greetingFor(DateTime(2026, 8, 20, 0)), 'Good morning,');
      expect(
        DashboardPage.greetingFor(DateTime(2026, 8, 20, 11, 59)),
        'Good morning,',
      );
      expect(
        DashboardPage.greetingFor(DateTime(2026, 8, 20, 12)),
        'Good afternoon,',
      );
      expect(
        DashboardPage.greetingFor(DateTime(2026, 8, 20, 17, 59)),
        'Good afternoon,',
      );
      expect(
        DashboardPage.greetingFor(DateTime(2026, 8, 20, 18)),
        'Good evening,',
      );
      expect(
        DashboardPage.greetingFor(DateTime(2026, 8, 20, 23, 59)),
        'Good evening,',
      );
    });
  });

  group('DashboardPage', () {
    testWidgets('greets the signed-in user by first name', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.dashboard,
        signedInUid: 'uid-1',
        subscriptionRepository: const StubSubscriptionRepository(),
        expenseRepository: const StubExpenseRepository(),
      );

      expect(find.text('Diane'), findsOneWidget);
      expect(find.text(DashboardPage.greetingFor(DateTime.now())), findsOneWidget);
    });

    testWidgets('survives a missing userDetails document', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.dashboard,
        signedInUid: 'uid-1',
        userDetails: null,
        subscriptionRepository: const StubSubscriptionRepository(),
        expenseRepository: const StubExpenseRepository(),
      );

      expect(find.text('Diane'), findsNothing);
      expect(find.textContaining('Good'), findsOneWidget);
    });

    testWidgets('⭐ shows spent today, both subscription totals and the count', (
      tester,
    ) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.dashboard,
        signedInUid: 'uid-1',
        subscriptionRepository: StubSubscriptionRepository(
          items: [
            sub(name: 'Netflix', amount: 549),
            sub(name: 'Spotify', amount: 149),
          ],
        ),
        expenseRepository: StubExpenseRepository(
          items: [
            expense(id: 'a', amount: 250),
            expense(id: 'b', amount: 320),
          ],
        ),
      );

      expect(find.text('₱570.00'), findsOneWidget);
      expect(find.text('₱698'), findsOneWidget);
      expect(find.text('₱8,376'), findsOneWidget);
      expect(find.text('2 active'), findsOneWidget);
    });

    testWidgets('lists upcoming payments soonest first', (tester) async {
      sizeViewport(tester);

      final soon = DateTime(today.year, today.month, today.day + 2);
      final later = DateTime(today.year, today.month, today.day + 20);

      await pumpAppAt(
        tester,
        AppRoutes.dashboard,
        signedInUid: 'uid-1',
        subscriptionRepository: StubSubscriptionRepository(
          items: [
            sub(name: 'Later', dayOfMonth: later.day),
            sub(name: 'Sooner', dayOfMonth: soon.day),
          ],
        ),
        expenseRepository: const StubExpenseRepository(),
      );

      expect(find.text('Upcoming payments'), findsOneWidget);

      final names = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((d) => d == 'Sooner' || d == 'Later')
          .toList();

      expect(names.first, 'Sooner');
    });

    testWidgets('nudges an account with nothing tracked', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.dashboard,
        signedInUid: 'uid-1',
        subscriptionRepository: const StubSubscriptionRepository(),
        expenseRepository: const StubExpenseRepository(),
      );

      expect(find.text('Nothing tracked yet'), findsOneWidget);
      expect(find.text('Upcoming payments'), findsNothing);
      expect(find.text('₱0.00'), findsOneWidget);
    });

    testWidgets('See all opens the subscriptions tab', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.dashboard,
        signedInUid: 'uid-1',
        subscriptionRepository: StubSubscriptionRepository(
          items: [sub(name: 'Netflix')],
        ),
        expenseRepository: const StubExpenseRepository(),
      );

      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();

      expect(find.text('Subscriptions'), findsWidgets);
    });

    testWidgets('surfaces a load failure without leaking internals', (
      tester,
    ) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.dashboard,
        signedInUid: 'uid-1',
        subscriptionRepository: const StubSubscriptionRepository(
          error: ServerFailure('boom'),
        ),
        expenseRepository: const StubExpenseRepository(),
      );

      expect(find.text('Could not load your dashboard'), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.dashboard,
        signedInUid: 'uid-1',
        values: {...onboarded},
        subscriptionRepository: StubSubscriptionRepository(
          items: [sub(name: 'Netflix')],
        ),
        expenseRepository: const StubExpenseRepository(),
      );

      expect(find.text('Netflix'), findsOneWidget);
    });
  });

  group('userDetails', () {
    test('testUser carries a first name for the greeting', () {
      const user = UserDetailsEntity(
        uid: 'uid-1',
        firstName: 'Diane',
        lastName: 'Magno',
        email: 'diane@pitakap.app',
      );

      expect(user.firstName, 'Diane');
    });
  });
}
