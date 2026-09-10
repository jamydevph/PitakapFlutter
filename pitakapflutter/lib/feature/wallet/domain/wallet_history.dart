import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';

/// One collapsible section of the history page: a wallet and every expense
/// charged to it, newest completed date first.
///
/// [walletId] is the empty string for the synthetic "unassigned" group, which
/// collects expenses that were logged without choosing a wallet. That group is
/// deliberately kept out of every balance calculation (see wallet_balances)
/// but still has to be visible, otherwise those expenses vanish from history.
class WalletHistoryGroup {
  final String walletId;
  final String name;
  final String description;
  final String currency;
  final List<ExpenseEntity> expenses;

  const WalletHistoryGroup({
    required this.walletId,
    required this.name,
    required this.description,
    required this.currency,
    required this.expenses,
  });

  bool get isUnassigned => walletId.isEmpty;

  int get count => expenses.length;

  double get total =>
      expenses.fold(0, (sum, expense) => sum + expense.amount);
}

/// Newest completed date first; ties broken by creation time then id so the
/// order is stable across rebuilds.
int compareByDateDescending(ExpenseEntity a, ExpenseEntity b) {
  final byDate = b.date.compareTo(a.date);
  if (byDate != 0) return byDate;

  final left = a.createdAt;
  final right = b.createdAt;

  if (left != null && right != null) {
    final byCreated = right.compareTo(left);
    if (byCreated != 0) return byCreated;
  }

  return a.id.compareTo(b.id);
}

List<ExpenseEntity> sortedByDateDescending(List<ExpenseEntity> expenses) {
  return [...expenses]..sort(compareByDateDescending);
}

/// Groups every expense under its wallet, preserving [wallets] order, and
/// appends an unassigned group last when there are expenses with no wallet.
/// Wallets with no expenses are still returned so an empty wallet is visible.
List<WalletHistoryGroup> walletHistoryGroups({
  required List<WalletEntity> wallets,
  required List<ExpenseEntity> expenses,
  required String unassignedName,
  required String unassignedDescription,
  required String fallbackCurrency,
}) {
  final groups = <WalletHistoryGroup>[];
  final known = {for (final wallet in wallets) wallet.id};

  for (final wallet in wallets) {
    groups.add(
      WalletHistoryGroup(
        walletId: wallet.id,
        name: wallet.name,
        description: wallet.description,
        currency: wallet.currency,
        expenses: sortedByDateDescending(
          expenses.where((expense) => expense.walletId == wallet.id).toList(),
        ),
      ),
    );
  }

  // An expense keeps its walletId even if that wallet was later deleted, so
  // "unassigned" means "no wallet we can still resolve", not just empty.
  final orphans = expenses
      .where((expense) => !known.contains(expense.walletId))
      .toList();

  if (orphans.isNotEmpty) {
    groups.add(
      WalletHistoryGroup(
        walletId: '',
        name: unassignedName,
        description: unassignedDescription,
        currency: fallbackCurrency,
        expenses: sortedByDateDescending(orphans),
      ),
    );
  }

  return groups;
}
