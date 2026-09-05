import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/feature/dashboard/domain/entities/spending_summary.dart';
import 'package:pitakapflutter/feature/dashboard/domain/usecases/get_spending_summary_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';

SubscriptionEntity sub({
  required String name,
  double amount = 100,
  BillingCycle cycle = BillingCycle.monthly,
  DateTime? firstBillDate,
  bool isActive = true,
  String category = 'entertainment',
}) {
  return SubscriptionEntity(
    id: name,
    userId: 'uid-1',
    name: name,
    category: category,
    amount: amount,
    billingCycle: cycle,
    firstBillDate: firstBillDate ?? DateTime(2024, 1, 15),
    isActive: isActive,
  );
}

ExpenseEntity expense({required double amount, String id = 'e'}) {
  return ExpenseEntity(
    id: id,
    userId: 'uid-1',
    description: 'Lunch',
    category: 'food',
    amount: amount,
    date: DateTime(2026, 8, 20),
  );
}

void main() {
  const useCase = GetSpendingSummaryUseCase();
  final now = DateTime(2026, 8, 20);

  GetSpendingSummaryUseCaseParams params({
    List<SubscriptionEntity> subscriptions = const [],
    List<ExpenseEntity> expenses = const [],
    int upcomingCount = GetSpendingSummaryUseCase.defaultUpcomingCount,
  }) {
    return GetSpendingSummaryUseCaseParams(
      subscriptions: subscriptions,
      expensesToday: expenses,
      now: now,
      upcomingCount: upcomingCount,
    );
  }

  group('spent today', () {
    test('sums the day\'s expenses', () {
      final summary = useCase.call(
        params(
          expenses: [
            expense(id: 'a', amount: 250),
            expense(id: 'b', amount: 320.50),
          ],
        ),
      );

      expect(summary.spentToday, 570.50);
    });

    test('is zero with no expenses', () {
      expect(useCase.call(params()).spentToday, 0);
    });
  });

  group('subscription totals', () {
    test('normalises every cycle to a monthly cost', () {
      final summary = useCase.call(
        params(
          subscriptions: [
            sub(name: 'Monthly', amount: 549),
            sub(name: 'Yearly', amount: 1200, cycle: BillingCycle.yearly),
            sub(name: 'Quarterly', amount: 300, cycle: BillingCycle.quarterly),
          ],
        ),
      );

      expect(summary.monthlySubscriptionCost, closeTo(549 + 100 + 100, 0.001));
    });

    test('yearly is exactly twelve times monthly', () {
      final summary = useCase.call(
        params(
          subscriptions: [
            sub(name: 'A', amount: 549),
            sub(name: 'B', amount: 149, cycle: BillingCycle.weekly),
            sub(name: 'C', amount: 1200, cycle: BillingCycle.yearly),
          ],
        ),
      );

      expect(
        summary.yearlySubscriptionCost,
        closeTo(summary.monthlySubscriptionCost * 12, 0.001),
      );
    });

    test('counts only active subscriptions', () {
      final summary = useCase.call(
        params(
          subscriptions: [
            sub(name: 'Live', amount: 100),
            sub(name: 'Paused', amount: 999, isActive: false),
          ],
        ),
      );

      expect(summary.activeSubscriptionCount, 1);
      expect(summary.monthlySubscriptionCost, 100);
    });

    test('an inactive subscription is excluded from upcoming payments', () {
      final summary = useCase.call(
        params(
          subscriptions: [sub(name: 'Paused', isActive: false)],
        ),
      );

      expect(summary.upcomingPayments, isEmpty);
      expect(summary.hasSubscriptions, isFalse);
    });
  });

  group('upcoming payments', () {
    test('orders by the computed due date, soonest first', () {
      final summary = useCase.call(
        params(
          subscriptions: [
            sub(name: 'Late', firstBillDate: DateTime(2024, 1, 28)),
            sub(name: 'Soon', firstBillDate: DateTime(2024, 1, 22)),
            sub(name: 'Middle', firstBillDate: DateTime(2024, 1, 25)),
          ],
        ),
      );

      expect(summary.upcomingPayments.map((p) => p.subscription.name), [
        'Soon',
        'Middle',
        'Late',
      ]);
    });

    test('ties break by name so the order is stable', () {
      final summary = useCase.call(
        params(
          subscriptions: [
            sub(name: 'Zeta', firstBillDate: DateTime(2024, 1, 25)),
            sub(name: 'alpha', firstBillDate: DateTime(2024, 1, 25)),
            sub(name: 'Mid', firstBillDate: DateTime(2024, 1, 25)),
          ],
        ),
      );

      expect(summary.upcomingPayments.map((p) => p.subscription.name), [
        'alpha',
        'Mid',
        'Zeta',
      ]);
    });

    test('caps the list at the requested count', () {
      final summary = useCase.call(
        params(
          subscriptions: [
            for (var day = 1; day <= 9; day++)
              sub(name: 'Sub $day', firstBillDate: DateTime(2024, 1, day)),
          ],
          upcomingCount: 5,
        ),
      );

      expect(summary.upcomingPayments, hasLength(5));
      expect(summary.activeSubscriptionCount, 9);
    });

    test('defaults to five', () {
      expect(GetSpendingSummaryUseCase.defaultUpcomingCount, 5);
    });

    test('carries the due date and days-until for each payment', () {
      final summary = useCase.call(
        params(
          subscriptions: [
            sub(name: 'Netflix', firstBillDate: DateTime(2024, 1, 22)),
          ],
        ),
      );

      final payment = summary.upcomingPayments.single;
      expect(payment.dueDate, DateTime(2026, 8, 22));
      expect(payment.daysUntil, 2);
    });

    test('the clock is a parameter — a later now shifts the whole list', () {
      final subscriptions = [
        sub(name: 'Early', firstBillDate: DateTime(2024, 1, 22)),
        sub(name: 'Later', firstBillDate: DateTime(2024, 1, 28)),
      ];

      final before = useCase.call(params(subscriptions: subscriptions));

      final after = const GetSpendingSummaryUseCase().call(
        GetSpendingSummaryUseCaseParams(
          subscriptions: subscriptions,
          expensesToday: const [],
          now: DateTime(2026, 8, 25),
        ),
      );

      expect(before.upcomingPayments.first.subscription.name, 'Early');
      expect(after.upcomingPayments.first.subscription.name, 'Later');
    });
  });

  group('empty', () {
    test('an account with nothing yields the empty summary', () {
      expect(useCase.call(params()), SpendingSummary.empty);
    });

    test('the summary has value equality', () {
      final a = useCase.call(
        params(subscriptions: [sub(name: 'Netflix', amount: 549)]),
      );
      final b = useCase.call(
        params(subscriptions: [sub(name: 'Netflix', amount: 549)]),
      );

      expect(a, b);
      expect(a, isNot(SpendingSummary.empty));
    });
  });
}
