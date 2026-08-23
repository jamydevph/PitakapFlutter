import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';

enum StatsMode {
  subscriptions('Subscriptions'),
  expenses('Expenses');

  const StatsMode(this.label);

  final String label;
}

enum SubscriptionView {
  monthly('Monthly'),
  yearly('Yearly');

  const SubscriptionView(this.label);

  final String label;
}

class CategorySlice {
  final String category;
  final double amount;
  final double share;

  const CategorySlice({
    required this.category,
    required this.amount,
    required this.share,
  });

  int get percent => (share * 100).round();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CategorySlice &&
            other.category == category &&
            other.amount == amount &&
            other.share == share;
  }

  @override
  int get hashCode => Object.hash(category, amount, share);
}

class CategoryBreakdown {
  final double total;
  final List<CategorySlice> slices;

  const CategoryBreakdown({required this.total, required this.slices});

  static const CategoryBreakdown empty = CategoryBreakdown(
    total: 0,
    slices: [],
  );

  bool get isEmpty => slices.isEmpty;
}

CategoryBreakdown buildBreakdown(Map<String, double> totals) {
  final positive = <String, double>{
    for (final entry in totals.entries)
      if (entry.value > 0) entry.key: entry.value,
  };

  final total = positive.values.fold<double>(0, (sum, value) => sum + value);

  if (total <= 0) return CategoryBreakdown.empty;

  final slices =
      positive.entries
          .map(
            (entry) => CategorySlice(
              category: entry.key,
              amount: entry.value,
              share: entry.value / total,
            ),
          )
          .toList()
        ..sort((a, b) {
          final byAmount = b.amount.compareTo(a.amount);
          if (byAmount != 0) return byAmount;

          return _categoryRank(a.category).compareTo(_categoryRank(b.category));
        });

  return CategoryBreakdown(total: total, slices: slices);
}

CategoryBreakdown expenseBreakdown(List<ExpenseEntity> expenses) {
  final totals = <String, double>{};

  for (final expense in expenses) {
    totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
  }

  return buildBreakdown(totals);
}

CategoryBreakdown subscriptionBreakdown(
  List<SubscriptionEntity> subscriptions, {
  required SubscriptionView view,
}) {
  final totals = <String, double>{};

  for (final subscription in subscriptions) {
    if (!subscription.isActive) continue;

    final amount = view == SubscriptionView.yearly
        ? subscription.yearlyCost
        : subscription.monthlyCost;

    totals[subscription.category] =
        (totals[subscription.category] ?? 0) + amount;
  }

  return buildBreakdown(totals);
}

int _categoryRank(String category) {
  final expenseRank = Constants.expenseCategories.indexOf(category);
  if (expenseRank >= 0) return expenseRank;

  final subscriptionRank = Constants.subscriptionCategories.indexOf(category);
  if (subscriptionRank >= 0) return subscriptionRank;

  return Constants.expenseCategories.length +
      Constants.subscriptionCategories.length;
}
