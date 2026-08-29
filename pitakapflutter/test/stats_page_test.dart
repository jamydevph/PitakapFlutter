import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/utils/billing_date_utils.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/restore_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/update_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';
import 'package:pitakapflutter/feature/stats/domain/category_breakdown.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/repository/subscription_repository.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/restore_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/update_subscription_usecase.dart';

import 'helpers.dart';

class MonthExpenseRepository implements ExpenseRepository {
  final Map<DateTime, List<ExpenseEntity>> byMonth;
  final Object? error;

  final List<WatchExpensesForMonthParams> monthQueries = [];

  MonthExpenseRepository({this.byMonth = const {}, this.error});

  @override
  Stream<List<ExpenseEntity>> watchExpensesForDay(
    WatchExpensesForDayParams params,
  ) {
    return Stream.value(const []);
  }

  @override
  Stream<List<ExpenseEntity>> watchExpensesForMonth(
    WatchExpensesForMonthParams params,
  ) {
    monthQueries.add(params);
    if (error != null) return Stream.error(error!);
    return Stream.value(byMonth[params.month] ?? const []);
  }

  @override
  Future<void> createExpense(CreateExpenseUseCaseParams params) async {}

  @override
  Future<void> updateExpense(UpdateExpenseUseCaseParams params) async {}

  @override
  Future<void> deleteExpense(DeleteExpenseUseCaseParams params) async {}

  @override
  Future<void> restoreExpense(RestoreExpenseUseCaseParams params) async {}
}

class StubSubscriptionRepository implements SubscriptionRepository {
  final List<SubscriptionEntity> items;

  const StubSubscriptionRepository({this.items = const []});

  @override
  Stream<List<SubscriptionEntity>> watchSubscriptions(String userId) {
    return Stream.value(items);
  }

  @override
  Future<void> createSubscription(CreateSubscriptionUseCaseParams p) async {}

  @override
  Future<void> updateSubscription(UpdateSubscriptionUseCaseParams p) async {}

  @override
  Future<void> deleteSubscription(DeleteSubscriptionUseCaseParams p) async {}

  @override
  Future<void> restoreSubscription(RestoreSubscriptionUseCaseParams p) async {}

  @override
  Future<void> rescheduleAllReminders(String userId) async {}
}

ExpenseEntity expense({
  required String id,
  required String category,
  required double amount,
  required DateTime date,
}) {
  return ExpenseEntity(
    id: id,
    userId: 'uid-1',
    description: 'x',
    category: category,
    amount: amount,
    date: date,
  );
}

SubscriptionEntity sub({
  required String name,
  required String category,
  required double amount,
}) {
  return SubscriptionEntity(
    id: name,
    userId: 'uid-1',
    name: name,
    category: category,
    amount: amount,
    billingCycle: BillingCycle.monthly,
    firstBillDate: DateTime(2024, 1, 15),
  );
}

void main() {
  final thisMonth = startOfMonth(DateTime.now());
  final lastMonth = DateTime(thisMonth.year, thisMonth.month - 1);

  void sizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('StatsPage — expenses', () {
    testWidgets('opens on expenses for the current month', (tester) async {
      sizeViewport(tester);

      final repository = MonthExpenseRepository(
        byMonth: {
          thisMonth: [
            expense(
              id: 'a',
              category: 'food',
              amount: 4320,
              date: thisMonth,
            ),
            expense(
              id: 'b',
              category: 'transport',
              amount: 2870,
              date: thisMonth,
            ),
          ],
        },
      );

      await pumpAppAt(
        tester,
        AppRoutes.stats,
        signedInUid: 'uid-1',
        expenseRepository: repository,
        subscriptionRepository: const StubSubscriptionRepository(),
      );

      expect(find.text('₱7,190'), findsOneWidget);
      expect(find.text('this month'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('₱4,320'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('⭐ the month query is a range over the selected month', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = MonthExpenseRepository();

      await pumpAppAt(
        tester,
        AppRoutes.stats,
        signedInUid: 'uid-1',
        expenseRepository: repository,
        subscriptionRepository: const StubSubscriptionRepository(),
      );

      final query = repository.monthQueries.first;
      expect(query.month, thisMonth);
      expect(query.nextMonth, DateTime(thisMonth.year, thisMonth.month + 1));
      expect(query.userId, 'uid-1');
    });

    testWidgets('stepping back re-queries the previous month', (tester) async {
      sizeViewport(tester);

      final repository = MonthExpenseRepository(
        byMonth: {
          thisMonth: [
            expense(id: 'a', category: 'food', amount: 100, date: thisMonth),
            expense(id: 'b', category: 'transport', amount: 40, date: thisMonth),
          ],
          lastMonth: [
            expense(
              id: 'c',
              category: 'groceries',
              amount: 900,
              date: lastMonth,
            ),
            expense(
              id: 'd',
              category: 'shopping',
              amount: 100,
              date: lastMonth,
            ),
          ],
        },
      );

      await pumpAppAt(
        tester,
        AppRoutes.stats,
        signedInUid: 'uid-1',
        expenseRepository: repository,
        subscriptionRepository: const StubSubscriptionRepository(),
      );

      expect(find.text('₱140'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('₱1,000'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(repository.monthQueries.last.month, lastMonth);
    });

    testWidgets('⭐ the next-month arrow is disabled on the current month', (
      tester,
    ) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.stats,
        signedInUid: 'uid-1',
        expenseRepository: MonthExpenseRepository(),
        subscriptionRepository: const StubSubscriptionRepository(),
      );

      final forward = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right),
          matching: find.byType(IconButton),
        ),
      );
      expect(forward.onPressed, isNull);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      final enabled = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right),
          matching: find.byType(IconButton),
        ),
      );
      expect(enabled.onPressed, isNotNull);
    });

    testWidgets('an empty month nudges rather than drawing an empty circle', (
      tester,
    ) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.stats,
        signedInUid: 'uid-1',
        expenseRepository: MonthExpenseRepository(),
        subscriptionRepository: const StubSubscriptionRepository(),
      );

      expect(find.text('Nothing logged this month'), findsOneWidget);
    });

    testWidgets('surfaces a load failure without leaking internals', (
      tester,
    ) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.stats,
        signedInUid: 'uid-1',
        expenseRepository: MonthExpenseRepository(
          error: const ServerFailure('boom'),
        ),
        subscriptionRepository: const StubSubscriptionRepository(),
      );

      expect(find.text('Could not load your statistics'), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
    });
  });

  group('StatsPage — subscriptions', () {
    testWidgets('⭐ switching mode shows subscription categories', (
      tester,
    ) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.stats,
        signedInUid: 'uid-1',
        expenseRepository: MonthExpenseRepository(),
        subscriptionRepository: StubSubscriptionRepository(
          items: [
            sub(name: 'Netflix', category: 'entertainment', amount: 549),
            sub(name: 'PLDT', category: 'utilities', amount: 1699),
          ],
        ),
      );

      await tester.tap(find.text(StatsMode.subscriptions.label));
      await tester.pumpAndSettle();

      expect(find.text('₱2,248'), findsOneWidget);
      expect(find.text('per month'), findsOneWidget);
      expect(find.text('Utilities'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsNothing);
    });

    testWidgets('⭐ the yearly view multiplies the monthly total by twelve', (
      tester,
    ) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.stats,
        signedInUid: 'uid-1',
        expenseRepository: MonthExpenseRepository(),
        subscriptionRepository: StubSubscriptionRepository(
          items: [
            sub(name: 'Netflix', category: 'entertainment', amount: 500),
            sub(name: 'PLDT', category: 'utilities', amount: 250),
          ],
        ),
      );

      await tester.tap(find.text(StatsMode.subscriptions.label));
      await tester.pumpAndSettle();
      expect(find.text('₱750'), findsOneWidget);

      await tester.tap(find.text(SubscriptionView.yearly.label));
      await tester.pumpAndSettle();

      expect(find.text('₱9,000'), findsOneWidget);
      expect(find.text('per year'), findsOneWidget);
    });

    testWidgets('an account with no subscriptions nudges', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.stats,
        signedInUid: 'uid-1',
        expenseRepository: MonthExpenseRepository(),
        subscriptionRepository: const StubSubscriptionRepository(),
      );

      await tester.tap(find.text(StatsMode.subscriptions.label));
      await tester.pumpAndSettle();

      expect(find.text('No active subscriptions'), findsOneWidget);
    });
  });
}
