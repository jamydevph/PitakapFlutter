import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/wallet_balances.dart';

WalletEntity wallet(String id, double opening) => WalletEntity(
  id: id,
  userId: 'u1',
  name: id,
  openingBalance: opening,
);

ExpenseEntity expense(String id, double amount, {String walletId = ''}) =>
    ExpenseEntity(
      id: id,
      userId: 'u1',
      description: id,
      category: 'food',
      amount: amount,
      walletId: walletId,
      date: DateTime(2026, 9, 10),
    );

void main() {
  final main5000 = wallet('main', 5000);
  final cash2000 = wallet('cash', 2000);

  group('availableBalance', () {
    test('a wallet with no expenses keeps its opening balance', () {
      expect(availableBalance(main5000, const []), 5000);
    });

    test('an assigned expense is deducted', () {
      final result = availableBalance(main5000, [
        expense('e1', 500, walletId: 'main'),
      ]);

      expect(result, 4500);
    });

    test('an unassigned expense affects no wallet', () {
      final result = availableBalance(main5000, [expense('e1', 500)]);

      expect(result, 5000);
    });

    test('an expense assigned elsewhere does not touch this wallet', () {
      final result = availableBalance(main5000, [
        expense('e1', 500, walletId: 'cash'),
      ]);

      expect(result, 5000);
    });
  });

  group('the same expense can never be deducted twice', () {
    test('folding the same list repeatedly yields the same balance', () {
      final expenses = [expense('e1', 500, walletId: 'main')];

      final first = availableBalance(main5000, expenses);
      final second = availableBalance(main5000, expenses);
      final third = availableBalance(main5000, expenses);

      expect(first, 4500);
      expect(second, 4500);
      expect(third, 4500);
    });
  });

  group('reassignment', () {
    test('moving an expense between wallets moves the whole amount', () {
      final before = [expense('e1', 500, walletId: 'main')];
      final after = [expense('e1', 500, walletId: 'cash')];

      expect(availableBalance(main5000, before), 4500);
      expect(availableBalance(cash2000, before), 2000);

      expect(availableBalance(main5000, after), 5000);
      expect(availableBalance(cash2000, after), 1500);
    });

    test('clearing the wallet restores the original balance', () {
      final assigned = [expense('e1', 500, walletId: 'main')];
      final cleared = [expense('e1', 500)];

      expect(availableBalance(main5000, assigned), 4500);
      expect(availableBalance(main5000, cleared), 5000);
    });

    test('deleting the expense restores the original balance', () {
      expect(
        availableBalance(main5000, [expense('e1', 500, walletId: 'main')]),
        4500,
      );
      expect(availableBalance(main5000, const []), 5000);
    });
  });

  group('balancesByWallet', () {
    test('folds every wallet in one pass', () {
      final result = balancesByWallet(
        [main5000, cash2000],
        [
          expense('e1', 500, walletId: 'main'),
          expense('e2', 250, walletId: 'cash'),
          expense('e3', 999),
        ],
      );

      expect(result, {'main': 4500, 'cash': 1750});
    });

    test('totalAvailable sums the wallets, ignoring unassigned spend', () {
      final total = totalAvailable(
        [main5000, cash2000],
        [expense('e1', 500, walletId: 'main'), expense('e2', 9999)],
      );

      expect(total, 6500);
    });
  });

  group('canAfford excludes the expense being edited', () {
    test('raising an amount is judged against the balance without it', () {
      final expenses = [expense('e1', 500, walletId: 'main')];

      expect(
        canAfford(
          wallet: main5000,
          expenses: expenses,
          editingExpenseId: 'e1',
          newAmount: 5000,
        ),
        isTrue,
      );

      expect(
        canAfford(
          wallet: main5000,
          expenses: expenses,
          editingExpenseId: 'e1',
          newAmount: 5001,
        ),
        isFalse,
      );
    });

    test('a new expense is judged against the full current balance', () {
      final expenses = [expense('e1', 500, walletId: 'main')];

      expect(
        canAfford(
          wallet: main5000,
          expenses: expenses,
          editingExpenseId: '',
          newAmount: 4500,
        ),
        isTrue,
      );

      expect(
        canAfford(
          wallet: main5000,
          expenses: expenses,
          editingExpenseId: '',
          newAmount: 4501,
        ),
        isFalse,
      );
    });
  });

  group('expensesForWallet', () {
    test('returns only that wallet, never the unassigned', () {
      final result = expensesForWallet([
        expense('e1', 500, walletId: 'main'),
        expense('e2', 250, walletId: 'cash'),
        expense('e3', 100),
      ], 'main');

      expect(result.map((e) => e.id), ['e1']);
    });

    test('an empty walletId matches nothing, never the unassigned', () {
      final result = expensesForWallet([expense('e3', 100)], '');

      expect(result, isEmpty);
    });
  });
}
