import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/wallet_history.dart';

WalletEntity wallet(String id, {String name = 'Main Wallet'}) {
  return WalletEntity(
    id: id,
    userId: 'uid-1',
    name: name,
    openingBalance: 5000,
  );
}

ExpenseEntity expense({
  required String id,
  required DateTime date,
  String walletId = '',
  double amount = 100,
  DateTime? createdAt,
}) {
  return ExpenseEntity(
    id: id,
    userId: 'uid-1',
    description: 'Lunch',
    category: 'food',
    amount: amount,
    walletId: walletId,
    date: date,
    createdAt: createdAt,
  );
}

List<WalletHistoryGroup> groupsFor(
  List<WalletEntity> wallets,
  List<ExpenseEntity> expenses,
) {
  return walletHistoryGroups(
    wallets: wallets,
    expenses: expenses,
    unassignedName: 'Unassigned',
    unassignedDescription: 'No wallet chosen',
    fallbackCurrency: 'PHP',
  );
}

void main() {
  group('grouping', () {
    test('every expense lands under its own wallet', () {
      final groups = groupsFor(
        [wallet('w1', name: 'Main'), wallet('w2', name: 'Savings')],
        [
          expense(id: 'e1', walletId: 'w1', date: DateTime(2026, 8, 5)),
          expense(id: 'e2', walletId: 'w2', date: DateTime(2026, 8, 4)),
          expense(id: 'e3', walletId: 'w1', date: DateTime(2026, 8, 3)),
        ],
      );

      expect(groups.map((g) => g.name), ['Main', 'Savings']);
      expect(groups.first.expenses.map((e) => e.id), ['e1', 'e3']);
      expect(groups.last.expenses.map((e) => e.id), ['e2']);
    });

    test('wallet order is preserved, not re-sorted', () {
      final groups = groupsFor(
        [wallet('w2', name: 'Savings'), wallet('w1', name: 'Main')],
        const [],
      );

      expect(groups.map((g) => g.name), ['Savings', 'Main']);
    });

    test('a wallet with no expenses is still shown', () {
      final groups = groupsFor([wallet('w1')], const []);

      expect(groups, hasLength(1));
      expect(groups.single.count, 0);
      expect(groups.single.total, 0);
    });

    test('the total is the sum of that wallet only', () {
      final groups = groupsFor(
        [wallet('w1', name: 'Main'), wallet('w2', name: 'Savings')],
        [
          expense(
            id: 'e1',
            walletId: 'w1',
            amount: 250,
            date: DateTime(2026, 8, 5),
          ),
          expense(
            id: 'e2',
            walletId: 'w1',
            amount: 320,
            date: DateTime(2026, 8, 3),
          ),
          expense(
            id: 'e3',
            walletId: 'w2',
            amount: 999,
            date: DateTime(2026, 8, 1),
          ),
        ],
      );

      expect(groups.first.total, 570);
      expect(groups.first.count, 2);
    });
  });

  group('unassigned', () {
    test('expenses with no wallet collect into a trailing group', () {
      final groups = groupsFor(
        [wallet('w1', name: 'Main')],
        [
          expense(id: 'e1', walletId: 'w1', date: DateTime(2026, 8, 5)),
          expense(id: 'e2', date: DateTime(2026, 8, 4)),
        ],
      );

      expect(groups, hasLength(2));
      expect(groups.last.isUnassigned, isTrue);
      expect(groups.last.name, 'Unassigned');
      expect(groups.last.expenses.map((e) => e.id), ['e2']);
    });

    test('no unassigned group appears when every expense has a wallet', () {
      final groups = groupsFor(
        [wallet('w1')],
        [expense(id: 'e1', walletId: 'w1', date: DateTime(2026, 8, 5))],
      );

      expect(groups, hasLength(1));
      expect(groups.single.isUnassigned, isFalse);
    });

    test('an expense pointing at a deleted wallet is not lost', () {
      final groups = groupsFor(
        [wallet('w1', name: 'Main')],
        [expense(id: 'e1', walletId: 'gone', date: DateTime(2026, 8, 5))],
      );

      expect(groups.last.isUnassigned, isTrue);
      expect(groups.last.expenses.map((e) => e.id), ['e1']);
    });
  });

  group('ordering inside a group', () {
    test('the latest completed date comes first', () {
      final groups = groupsFor(
        [wallet('w1')],
        [
          expense(id: 'old', walletId: 'w1', date: DateTime(2026, 7, 29)),
          expense(id: 'new', walletId: 'w1', date: DateTime(2026, 8, 5)),
          expense(id: 'mid', walletId: 'w1', date: DateTime(2026, 8, 3)),
        ],
      );

      expect(groups.single.expenses.map((e) => e.id), ['new', 'mid', 'old']);
    });

    test('same-day expenses fall back to newest created first', () {
      final day = DateTime(2026, 8, 5);

      final groups = groupsFor(
        [wallet('w1')],
        [
          expense(
            id: 'earlier',
            walletId: 'w1',
            date: day,
            createdAt: DateTime(2026, 8, 5, 9),
          ),
          expense(
            id: 'later',
            walletId: 'w1',
            date: day,
            createdAt: DateTime(2026, 8, 5, 18),
          ),
        ],
      );

      expect(groups.single.expenses.map((e) => e.id), ['later', 'earlier']);
    });

    test('ordering is stable when nothing distinguishes two rows', () {
      final day = DateTime(2026, 8, 5);
      final expenses = [
        expense(id: 'b', walletId: 'w1', date: day),
        expense(id: 'a', walletId: 'w1', date: day),
      ];

      expect(
        groupsFor([wallet('w1')], expenses).single.expenses.map((e) => e.id),
        ['a', 'b'],
      );
      expect(
        groupsFor([wallet('w1')], expenses.reversed.toList())
            .single
            .expenses
            .map((e) => e.id),
        ['a', 'b'],
      );
    });

    test('sorting does not mutate the list it was handed', () {
      final expenses = [
        expense(id: 'old', walletId: 'w1', date: DateTime(2026, 7, 1)),
        expense(id: 'new', walletId: 'w1', date: DateTime(2026, 8, 1)),
      ];

      sortedByDateDescending(expenses);

      expect(expenses.map((e) => e.id), ['old', 'new']);
    });
  });
}
