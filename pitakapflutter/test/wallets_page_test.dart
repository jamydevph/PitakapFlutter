import 'dart:async';

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
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/restore_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/update_wallet_usecase.dart';

import 'helpers.dart';

class FakeWalletRepository implements WalletRepository {
  final List<WalletEntity> _wallets;
  final Object? error;

  final List<String> deleted = [];
  final List<WalletEntity> restored = [];
  final List<CreateWalletUseCaseParams> created = [];

  final StreamController<List<WalletEntity>> _controller =
      StreamController<List<WalletEntity>>.broadcast();

  FakeWalletRepository({List<WalletEntity>? wallets, this.error})
    : _wallets = List.of(wallets ?? const []);

  @override
  Stream<List<WalletEntity>> watchWallets(String userId) {
    if (error != null) return Stream.error(error!);

    return _controller.stream.startWith(List.of(_wallets));
  }

  @override
  Future<void> createWallet(CreateWalletUseCaseParams params) async {
    created.add(params);
  }

  @override
  Future<void> updateWallet(UpdateWalletUseCaseParams params) async {}

  @override
  Future<void> deleteWallet(DeleteWalletUseCaseParams params) async {
    deleted.add(params.walletId);
    _wallets.removeWhere((wallet) => wallet.id == params.walletId);
    _controller.add(List.of(_wallets));
  }

  @override
  Future<void> restoreWallet(RestoreWalletUseCaseParams params) async {
    restored.add(params.wallet);
    _wallets.add(params.wallet);
    _controller.add(List.of(_wallets));
  }

  void dispose() => _controller.close();
}

extension _StartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
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

WalletEntity wallet(String id, String name, double opening) {
  return WalletEntity(
    id: id,
    userId: 'uid-1',
    name: name,
    description: 'Everyday spending',
    openingBalance: opening,
  );
}

ExpenseEntity spend(String id, String walletId, double amount) {
  return ExpenseEntity(
    id: id,
    userId: 'uid-1',
    description: 'Lunch',
    category: 'food',
    amount: amount,
    walletId: walletId,
    date: DateTime(2026, 8, 5),
  );
}

void main() {
  void sizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  FakeWalletRepository repositoryWith(List<WalletEntity> wallets) {
    final repository = FakeWalletRepository(wallets: wallets);
    addTearDown(repository.dispose);
    return repository;
  }

  testWidgets('an account with no wallets is invited to add one', (
    tester,
  ) async {
    sizeViewport(tester);

    await pumpAppAt(
      tester,
      AppRoutes.wallets,
      signedInUid: 'uid-1',
      walletRepository: repositoryWith(const []),
    );

    expect(find.text(Strings.walletsEmptyTitle), findsOneWidget);
    expect(find.text(Strings.walletAddAction), findsOneWidget);
  });

  testWidgets('each wallet shows its opening balance minus its spend', (
    tester,
  ) async {
    sizeViewport(tester);

    await pumpAppAt(
      tester,
      AppRoutes.wallets,
      signedInUid: 'uid-1',
      walletRepository: repositoryWith([
        wallet('w1', 'Main Wallet', 5000),
        wallet('w2', 'Savings Wallet', 3000),
      ]),
      expenseRepository: StubExpenseRepository([
        spend('e1', 'w1', 730),
      ]),
    );

    expect(find.text('Main Wallet'), findsOneWidget);
    expect(find.text('₱4,270.00'), findsOneWidget);
    expect(find.text('₱3,000.00'), findsOneWidget);
  });

  testWidgets('the total balance is the sum of what is left', (tester) async {
    sizeViewport(tester);

    await pumpAppAt(
      tester,
      AppRoutes.wallets,
      signedInUid: 'uid-1',
      walletRepository: repositoryWith([
        wallet('w1', 'Main Wallet', 5000),
        wallet('w2', 'Savings Wallet', 3000),
        wallet('w3', 'Cash on Hand', 2000),
      ]),
      expenseRepository: StubExpenseRepository([
        spend('e1', 'w1', 730),
      ]),
    );

    expect(find.text(Strings.totalBalanceLabel), findsOneWidget);
    expect(find.text('₱9,270.00'), findsOneWidget);
  });

  testWidgets('spend with no wallet never moves a balance', (tester) async {
    sizeViewport(tester);

    await pumpAppAt(
      tester,
      AppRoutes.wallets,
      signedInUid: 'uid-1',
      walletRepository: repositoryWith([wallet('w1', 'Main Wallet', 5000)]),
      expenseRepository: StubExpenseRepository([
        spend('e1', '', 9999),
      ]),
    );

    expect(find.text('₱5,000.00'), findsWidgets);
  });

  testWidgets('a load failure explains itself instead of hanging', (
    tester,
  ) async {
    sizeViewport(tester);

    final repository = FakeWalletRepository(error: Exception('nope'));
    addTearDown(repository.dispose);

    await pumpAppAt(
      tester,
      AppRoutes.wallets,
      signedInUid: 'uid-1',
      walletRepository: repository,
    );

    expect(find.text(Strings.walletsLoadFailed), findsOneWidget);
  });
}
