import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';

double spentFromWallet(List<ExpenseEntity> expenses, String walletId) {
  if (walletId.isEmpty) return 0;

  return expenses
      .where((expense) => expense.walletId == walletId)
      .fold(0, (sum, expense) => sum + expense.amount);
}

double availableBalance(WalletEntity wallet, List<ExpenseEntity> expenses) {
  return wallet.openingBalance - spentFromWallet(expenses, wallet.id);
}

Map<String, double> balancesByWallet(
  List<WalletEntity> wallets,
  List<ExpenseEntity> expenses,
) {
  return {
    for (final wallet in wallets)
      wallet.id: availableBalance(wallet, expenses),
  };
}

double totalAvailable(
  List<WalletEntity> wallets,
  List<ExpenseEntity> expenses,
) {
  return balancesByWallet(
    wallets,
    expenses,
  ).values.fold(0, (sum, balance) => sum + balance);
}

List<ExpenseEntity> expensesForWallet(
  List<ExpenseEntity> expenses,
  String walletId,
) {
  if (walletId.isEmpty) return const [];

  return expenses.where((expense) => expense.walletId == walletId).toList();
}

double balanceAfterChange({
  required WalletEntity wallet,
  required List<ExpenseEntity> expenses,
  required String editingExpenseId,
  required double newAmount,
}) {
  final withoutEdited = expenses
      .where((expense) => expense.id != editingExpenseId)
      .toList();

  return availableBalance(wallet, withoutEdited) - newAmount;
}

bool canAfford({
  required WalletEntity wallet,
  required List<ExpenseEntity> expenses,
  required String editingExpenseId,
  required double newAmount,
}) {
  return balanceAfterChange(
        wallet: wallet,
        expenses: expenses,
        editingExpenseId: editingExpenseId,
        newAmount: newAmount,
      ) >=
      0;
}
