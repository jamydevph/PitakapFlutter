import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/restore_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/update_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';
import 'package:pitakapflutter/feature/history/presentation/history_page.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/restore_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/update_wallet_usecase.dart';

import 'helpers.dart';

class StubWalletRepository implements WalletRepository {
  final List<WalletEntity> wallets;
  final Object? error;

  const StubWalletRepository(this.wallets, {this.error});

  @override
  Stream<List<WalletEntity>> watchWallets(String userId) {
    if (error != null) return Stream.error(error!);

    return Stream.value(wallets);
  }

  @override
  Future<void> createWallet(CreateWalletUseCaseParams params) async {}

  @override
  Future<void> updateWallet(UpdateWalletUseCaseParams params) async {}

  @override
  Future<void> deleteWallet(DeleteWalletUseCaseParams params) async {}

  @override
  Future<void> restoreWallet(RestoreWalletUseCaseParams params) async {}
}

class StubExpenseRepository implements ExpenseRepository {
  final List<ExpenseEntity> expenses;

  const StubExpenseRepository(this.expenses);

  @override
  Stream<List<ExpenseEntity>> watchAllExpenses(String userId) {
    return Stream.value(expenses);
  }

  @override
  Stream<List<ExpenseEntity>> watchExpensesForDay(
    WatchExpensesForDayParams params,
  ) => Stream.value(const []);

  @override
  Stream<List<ExpenseEntity>> watchExpensesForMonth(
    WatchExpensesForMonthParams params,
  ) => Stream.value(const []);

  @override
  Future<void> createExpense(CreateExpenseUseCaseParams params) async {}

  @override
  Future<void> updateExpense(UpdateExpenseUseCaseParams params) async {}

  @override
  Future<void> deleteExpense(DeleteExpenseUseCaseParams params) async {}

  @override
  Future<void> restoreExpense(RestoreExpenseUseCaseParams params) async {}
}

WalletEntity wallet(String id, String name) {
  return WalletEntity(
    id: id,
    userId: 'uid-1',
    name: name,
    openingBalance: 5000,
  );
}

ExpenseEntity spend({
  required String id,
  required String description,
  required String walletId,
  required DateTime date,
  double amount = 250,
}) {
  return ExpenseEntity(
    id: id,
    userId: 'uid-1',
    description: description,
    category: 'food',
    amount: amount,
    walletId: walletId,
    date: date,
  );
}

void main() {
  void sizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  final main = wallet('w1', 'Main Wallet');
  final savings = wallet('w2', 'Savings Wallet');

  final lunch = spend(
    id: 'e1',
    description: 'Lunch at Jollibee',
    walletId: 'w1',
    date: DateTime(2026, 8, 5),
  );
  final grab = spend(
    id: 'e2',
    description: 'Grab to BGC',
    walletId: 'w1',
    date: DateTime(2026, 8, 3),
    amount: 320,
  );
  final milkTea = spend(
    id: 'e3',
    description: 'Milk tea',
    walletId: 'w2',
    date: DateTime(2026, 7, 29),
    amount: 160,
  );

  Future<void> pumpHistory(
    WidgetTester tester, {
    List<WalletEntity> wallets = const [],
    List<ExpenseEntity> expenses = const [],
  }) async {
    sizeViewport(tester);

    await pumpAppAt(
      tester,
      AppRoutes.history,
      signedInUid: 'uid-1',
      walletRepository: StubWalletRepository(wallets),
      expenseRepository: StubExpenseRepository(expenses),
    );
  }

  group('grouping', () {
    testWidgets('every wallet gets its own header', (tester) async {
      await pumpHistory(
        tester,
        wallets: [main, savings],
        expenses: [lunch, grab, milkTea],
      );

      expect(find.text('Main Wallet'), findsOneWidget);
      expect(find.text('Savings Wallet'), findsOneWidget);
    });

    testWidgets('a header counts only its own expenses', (tester) async {
      await pumpHistory(
        tester,
        wallets: [main, savings],
        expenses: [lunch, grab, milkTea],
      );

      expect(find.text('2 ${Strings.historyExpensesSuffix}'), findsOneWidget);
    });

    testWidgets('a single expense is not pluralised', (tester) async {
      await pumpHistory(tester, wallets: [main], expenses: [lunch]);

      expect(find.text('1 ${Strings.historyExpenseSuffix}'), findsOneWidget);
    });
  });

  group('expanding', () {
    testWidgets('the first wallet opens so the page is never all bars', (
      tester,
    ) async {
      await pumpHistory(
        tester,
        wallets: [main, savings],
        expenses: [lunch, grab, milkTea],
      );

      expect(find.text('Lunch at Jollibee'), findsOneWidget);
      expect(find.text('Milk tea'), findsNothing);
    });

    testWidgets('a collapsed wallet invites a tap', (tester) async {
      await pumpHistory(
        tester,
        wallets: [main, savings],
        expenses: [lunch, milkTea],
      );

      expect(
        find.textContaining(Strings.historyTapToExpand),
        findsOneWidget,
      );
    });

    testWidgets('tapping a collapsed wallet reveals its expenses', (
      tester,
    ) async {
      await pumpHistory(
        tester,
        wallets: [main, savings],
        expenses: [lunch, milkTea],
      );

      await tester.tap(find.text('Savings Wallet'));
      await tester.pumpAndSettle();

      expect(find.text('Milk tea'), findsOneWidget);
    });

    testWidgets('tapping an open wallet folds it away again', (tester) async {
      await pumpHistory(tester, wallets: [main], expenses: [lunch]);

      expect(find.text('Lunch at Jollibee'), findsOneWidget);

      await tester.tap(find.text('Main Wallet'));
      await tester.pumpAndSettle();

      expect(find.text('Lunch at Jollibee'), findsNothing);
    });
  });

  group('rows', () {
    testWidgets('the newest completed date comes first', (tester) async {
      await pumpHistory(tester, wallets: [main], expenses: [grab, lunch]);

      final rows = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .toList();

      expect(
        rows.indexOf('Lunch at Jollibee'),
        lessThan(rows.indexOf('Grab to BGC')),
      );
    });

    testWidgets('each row carries its completed date', (tester) async {
      await pumpHistory(tester, wallets: [main], expenses: [lunch]);

      expect(
        find.textContaining(
          HistoryPage.formatCompletedDate(DateTime(2026, 8, 5)),
        ),
        findsOneWidget,
      );
    });
  });

  group('edge cases', () {
    testWidgets('expenses with no wallet still appear', (tester) async {
      await pumpHistory(
        tester,
        wallets: [main],
        expenses: [
          lunch,
          spend(
            id: 'orphan',
            description: 'Mystery snack',
            walletId: '',
            date: DateTime(2026, 8, 1),
          ),
        ],
      );

      expect(find.text(Strings.historyUnassignedTitle), findsOneWidget);
    });

    testWidgets('an account with nothing logged says so', (tester) async {
      await pumpHistory(tester);

      expect(find.text(Strings.historyEmptyTitle), findsOneWidget);
    });

    testWidgets('a load failure explains itself', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.history,
        signedInUid: 'uid-1',
        walletRepository: StubWalletRepository(
          const [],
          error: Exception('nope'),
        ),
      );

      expect(find.text(Strings.historyLoadFailed), findsOneWidget);
    });
  });
}
