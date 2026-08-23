import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/stats/domain/category_breakdown.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';

ExpenseEntity expense({
  required String category,
  required double amount,
  String id = 'e',
}) {
  return ExpenseEntity(
    id: id,
    userId: 'uid-1',
    description: 'x',
    category: category,
    amount: amount,
    date: DateTime(2026, 8, 20),
  );
}

SubscriptionEntity sub({
  required String category,
  required double amount,
  String name = 's',
  BillingCycle cycle = BillingCycle.monthly,
  bool isActive = true,
}) {
  return SubscriptionEntity(
    id: name,
    userId: 'uid-1',
    name: name,
    category: category,
    amount: amount,
    billingCycle: cycle,
    firstBillDate: DateTime(2024, 1, 15),
    isActive: isActive,
  );
}

void main() {
  group('expenseBreakdown', () {
    test('sums by category and computes each share', () {
      final breakdown = expenseBreakdown([
        expense(id: 'a', category: 'food', amount: 4320),
        expense(id: 'b', category: 'groceries', amount: 3120),
        expense(id: 'c', category: 'transport', amount: 2870),
        expense(id: 'd', category: 'shopping', amount: 2170),
      ]);

      expect(breakdown.total, 12480);
      expect(breakdown.slices.map((s) => s.category), [
        'food',
        'groceries',
        'transport',
        'shopping',
      ]);
      expect(breakdown.slices.map((s) => s.percent), [35, 25, 23, 17]);
    });

    test('merges repeated categories', () {
      final breakdown = expenseBreakdown([
        expense(id: 'a', category: 'food', amount: 100),
        expense(id: 'b', category: 'food', amount: 150),
        expense(id: 'c', category: 'transport', amount: 50),
      ]);

      expect(breakdown.total, 300);
      expect(breakdown.slices, hasLength(2));
      expect(breakdown.slices.first.category, 'food');
      expect(breakdown.slices.first.amount, 250);
    });

    test('orders by amount, largest first', () {
      final breakdown = expenseBreakdown([
        expense(id: 'a', category: 'food', amount: 10),
        expense(id: 'b', category: 'transport', amount: 90),
        expense(id: 'c', category: 'groceries', amount: 50),
      ]);

      expect(breakdown.slices.map((s) => s.category), [
        'transport',
        'groceries',
        'food',
      ]);
    });

    test('⭐ equal amounts fall back to the canonical category order', () {
      final breakdown = expenseBreakdown([
        expense(id: 'a', category: 'shopping', amount: 100),
        expense(id: 'b', category: 'food', amount: 100),
        expense(id: 'c', category: 'transport', amount: 100),
      ]);

      expect(breakdown.slices.map((s) => s.category), [
        'food',
        'transport',
        'shopping',
      ]);
    });

    test('an empty list is the empty breakdown', () {
      final breakdown = expenseBreakdown(const []);

      expect(breakdown.isEmpty, isTrue);
      expect(breakdown.total, 0);
    });

    test('⭐ shares always sum to one', () {
      final breakdown = expenseBreakdown([
        expense(id: 'a', category: 'food', amount: 33.33),
        expense(id: 'b', category: 'transport', amount: 33.33),
        expense(id: 'c', category: 'groceries', amount: 33.34),
      ]);

      final sum = breakdown.slices.fold<double>(0, (t, s) => t + s.share);
      expect(sum, closeTo(1, 0.000001));
    });
  });

  group('subscriptionBreakdown', () {
    test('uses monthly cost in the monthly view', () {
      final breakdown = subscriptionBreakdown(
        [
          sub(name: 'Netflix', category: 'entertainment', amount: 549),
          sub(
            name: 'Domain',
            category: 'utilities',
            amount: 1200,
            cycle: BillingCycle.yearly,
          ),
        ],
        view: SubscriptionView.monthly,
      );

      expect(breakdown.total, closeTo(549 + 100, 0.001));
    });

    test('⭐ the yearly view is exactly twelve times the monthly view', () {
      final subscriptions = [
        sub(name: 'Netflix', category: 'entertainment', amount: 549),
        sub(
          name: 'Gym',
          category: 'health',
          amount: 149,
          cycle: BillingCycle.weekly,
        ),
      ];

      final monthly = subscriptionBreakdown(
        subscriptions,
        view: SubscriptionView.monthly,
      );
      final yearly = subscriptionBreakdown(
        subscriptions,
        view: SubscriptionView.yearly,
      );

      expect(yearly.total, closeTo(monthly.total * 12, 0.001));
    });

    test('⭐ excludes inactive subscriptions', () {
      final breakdown = subscriptionBreakdown(
        [
          sub(name: 'Live', category: 'entertainment', amount: 100),
          sub(
            name: 'Paused',
            category: 'utilities',
            amount: 999,
            isActive: false,
          ),
        ],
        view: SubscriptionView.monthly,
      );

      expect(breakdown.total, 100);
      expect(breakdown.slices, hasLength(1));
    });

    test('no active subscriptions is the empty breakdown', () {
      final breakdown = subscriptionBreakdown(
        [sub(name: 'Paused', category: 'utilities', amount: 10, isActive: false)],
        view: SubscriptionView.monthly,
      );

      expect(breakdown.isEmpty, isTrue);
    });
  });

  group('buildBreakdown', () {
    test('drops zero and negative totals rather than drawing empty slices', () {
      final breakdown = buildBreakdown({
        'food': 100,
        'transport': 0,
        'groceries': -50,
      });

      expect(breakdown.slices.map((s) => s.category), ['food']);
      expect(breakdown.total, 100);
    });

    test('a single category is the whole circle', () {
      final breakdown = buildBreakdown({'food': 250});

      expect(breakdown.slices.single.share, 1);
      expect(breakdown.slices.single.percent, 100);
    });

    test('slices have value equality', () {
      const a = CategorySlice(category: 'food', amount: 10, share: 0.5);
      const b = CategorySlice(category: 'food', amount: 10, share: 0.5);

      expect(a, b);
    });
  });
}
