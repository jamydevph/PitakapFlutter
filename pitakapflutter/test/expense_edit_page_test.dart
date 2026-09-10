import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/utils/date_utils.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/restore_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/update_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';
import 'package:pitakapflutter/feature/expense/presentation/providers/selected_day_controller.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/restore_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/update_wallet_usecase.dart';

import 'helpers.dart';

class RecordingExpenseRepository implements ExpenseRepository {
  final List<ExpenseEntity> forToday;
  final Object? createError;

  final List<CreateExpenseUseCaseParams> created = [];
  final List<ExpenseEntity> updated = [];

  Completer<void>? gate;

  RecordingExpenseRepository({this.forToday = const [], this.createError});

  @override
  Stream<List<ExpenseEntity>> watchAllExpenses(String userId) {
    return Stream.value(const []);
  }

  @override
  Stream<List<ExpenseEntity>> watchExpensesForDay(
    WatchExpensesForDayParams params,
  ) {
    return Stream.value(List.of(forToday));
  }

  @override
  Stream<List<ExpenseEntity>> watchExpensesForMonth(
    WatchExpensesForMonthParams params,
  ) {
    return Stream.value(const []);
  }

  @override
  Future<void> createExpense(CreateExpenseUseCaseParams params) async {
    created.add(params);
    if (gate != null) await gate!.future;
    if (createError != null) throw createError!;
  }

  @override
  Future<void> updateExpense(UpdateExpenseUseCaseParams params) async {
    updated.add(params.expense);
  }

  @override
  Future<void> deleteExpense(DeleteExpenseUseCaseParams params) async {}

  @override
  Future<void> restoreExpense(RestoreExpenseUseCaseParams params) async {}
}

class StubWalletRepository implements WalletRepository {
  final List<WalletEntity> wallets;

  const StubWalletRepository(this.wallets);

  @override
  Stream<List<WalletEntity>> watchWallets(String userId) =>
      Stream.value(wallets);

  @override
  Future<void> createWallet(CreateWalletUseCaseParams params) async {}

  @override
  Future<void> updateWallet(UpdateWalletUseCaseParams params) async {}

  @override
  Future<void> deleteWallet(DeleteWalletUseCaseParams params) async {}

  @override
  Future<void> restoreWallet(RestoreWalletUseCaseParams params) async {}
}

ExpenseEntity expense({
  required DateTime date,
  String id = 'e1',
  String description = 'Lunch at Jollibee',
  String category = 'food',
  double amount = 250,
  String paymentMethod = 'cash',
  String walletId = '',
  DateTime? createdAt,
}) {
  return ExpenseEntity(
    id: id,
    userId: 'uid-1',
    description: description,
    category: category,
    amount: amount,
    paymentMethod: paymentMethod,
    walletId: walletId,
    date: date,
    createdAt: createdAt,
  );
}

void main() {
  final today = startOfDay(DateTime.now());

  void sizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> fillAmount(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextFormField).first, value);
    await tester.pumpAndSettle();
  }

  Future<void> fillDescription(WidgetTester tester, String value) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      value,
    );
    await tester.pumpAndSettle();
  }

  group('creating an expense', () {
    testWidgets('the list FAB opens the form', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: RecordingExpenseRepository(),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add expense'), findsOneWidget);
      expect(find.text('Save expense'), findsOneWidget);
    });

    testWidgets('a filled form reaches the repository intact', (tester) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository();

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await fillAmount(tester, '250.50');
      await fillDescription(tester, 'Lunch at Jollibee');

      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GCash'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));

      final params = repository.created.single;
      expect(params.userId, 'uid-1');
      expect(params.amount, 250.5);
      expect(params.description, 'Lunch at Jollibee');
      expect(params.category, 'transport');
      expect(params.paymentMethod, 'gcash');
      expect(params.date, today);
    });

    testWidgets('the date defaults to the SELECTED day, not today', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository();
      final yesterday = DateTime(today.year, today.month, today.day - 1);

      final container = await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      container.read(selectedDayProvider.notifier).select(yesterday);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await fillAmount(tester, '120');
      await fillDescription(tester, 'Tricycle');
      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created.single.date, yesterday);
    });

    testWidgets('payment method is optional and defaults to not recorded', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository();

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await fillAmount(tester, '80');
      await fillDescription(tester, 'Coffee');
      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created.single.paymentMethod, '');
    });

    testWidgets('tapping a chosen payment method again clears it', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository();

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await fillAmount(tester, '80');
      await fillDescription(tester, 'Coffee');

      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created.single.paymentMethod, '');
    });
  });

  group('validation', () {
    testWidgets('an empty form does not reach the repository', (tester) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository();

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created, isEmpty);
      expect(find.text('Amount is required'), findsOneWidget);
      expect(find.text('Description is required'), findsOneWidget);
    });

    testWidgets('a zero amount is rejected', (tester) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository();

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await fillAmount(tester, '0');
      await fillDescription(tester, 'Nothing');
      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created, isEmpty);
      expect(find.text('Enter a valid amount'), findsOneWidget);
    });

    testWidgets('letters never reach the validator — the formatter strips '
        'them, so the amount reads as MISSING not invalid', (tester) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository();

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await fillAmount(tester, 'abc');
      await fillDescription(tester, 'Milk tea');
      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created, isEmpty);
      expect(find.text('Amount is required'), findsOneWidget);
      expect(find.text('Enter a valid amount'), findsNothing);
    });

    testWidgets('a minus sign is stripped, so -250 saves as 250', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository();

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await fillAmount(tester, '-250');
      await fillDescription(tester, 'Refund');
      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));
      expect(repository.created.single.amount, 250);
    });

    testWidgets('a whitespace-only description counts as missing', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository();

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await fillAmount(tester, '250');
      await fillDescription(tester, '   ');
      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created, isEmpty);
      expect(find.text('Description is required'), findsOneWidget);
    });

    testWidgets('a thousands separator is stripped, not truncated at — '
        '"1,500" saves as 1500 (was ₱1 before Day 29)', (tester) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository();

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await fillAmount(tester, '1,500');
      await fillDescription(tester, 'Groceries');
      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));
      expect(repository.created.single.amount, 1500);
    });
  });

  group('editing an expense', () {
    testWidgets('tapping a row opens the form prefilled', (tester) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository(
        forToday: [expense(date: today, paymentMethod: 'gcash')],
      );

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.text('Lunch at Jollibee'));
      await tester.pumpAndSettle();

      expect(find.text('Edit expense'), findsOneWidget);
      expect(find.text('250.00'), findsOneWidget);
      expect(find.text('Lunch at Jollibee'), findsOneWidget);
    });

    testWidgets('an edit preserves id, userId, currency and createdAt', (
      tester,
    ) async {
      sizeViewport(tester);

      final createdAt = DateTime(2026, 1, 2, 3, 4);
      final repository = RecordingExpenseRepository(
        forToday: [
          expense(date: today, paymentMethod: 'gcash', createdAt: createdAt),
        ],
      );

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.text('Lunch at Jollibee'));
      await tester.pumpAndSettle();

      await fillDescription(tester, 'Dinner at Jollibee');
      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.updated, hasLength(1));

      final saved = repository.updated.single;
      expect(saved.id, 'e1');
      expect(saved.userId, 'uid-1');
      expect(saved.currency, 'PHP');
      expect(saved.createdAt, createdAt);
      expect(saved.description, 'Dinner at Jollibee');
      expect(saved.amount, 250);
    });

    testWidgets('editing an expense keeps the wallet it was charged to', (
      tester,
    ) async {
      // Regression: the update path rebuilt the entity without walletId, and
      // because walletId is a writable field that empty string was persisted
      // over the real assignment. Editing an amount silently unassigned the
      // expense from its wallet and inflated that wallet's balance.
      final repository = RecordingExpenseRepository(
        forToday: [expense(date: today, walletId: 'w1')],
      );

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.text('Lunch at Jollibee'));
      await tester.pumpAndSettle();

      await fillDescription(tester, 'Dinner at Jollibee');
      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.updated.single.walletId, 'w1');
    });
  });

  group('wallet assignment', () {
    const mainWallet = WalletEntity(
      id: 'w1',
      userId: 'uid-1',
      name: 'Main Wallet',
      openingBalance: 1000,
    );

    Future<RecordingExpenseRepository> openForm(
      WidgetTester tester, {
      List<ExpenseEntity> existing = const [],
    }) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository(forToday: existing);

      await pumpAppAt(
        tester,
        AppRoutes.expenseNew,
        signedInUid: 'uid-1',
        expenseRepository: repository,
        walletRepository: const StubWalletRepository([mainWallet]),
      );

      await tester.scrollUntilVisible(
        find.text(Strings.expenseWalletLabel),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      return repository;
    }

    testWidgets('the form offers each wallet plus an unassigned option', (
      tester,
    ) async {
      await openForm(tester);

      expect(find.text(Strings.expenseWalletLabel), findsOneWidget);
      expect(find.text(Strings.expenseWalletNone), findsOneWidget);
      expect(find.text('Main Wallet'), findsOneWidget);
    });

    testWidgets('choosing a wallet sends its id through on create', (
      tester,
    ) async {
      final repository = await openForm(tester);

      await fillAmount(tester, '250');
      await fillDescription(tester, 'Lunch at Jollibee');
      await tester.tap(find.text('Main Wallet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created.single.walletId, 'w1');
    });

    testWidgets('an expense with no wallet saves with an empty walletId', (
      tester,
    ) async {
      final repository = await openForm(tester);

      await fillAmount(tester, '250');
      await fillDescription(tester, 'Lunch at Jollibee');

      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created.single.walletId, isEmpty);
    });

    testWidgets('a wallet may not be overdrawn', (tester) async {
      final repository = await openForm(tester);

      await fillAmount(tester, '2000');
      await fillDescription(tester, 'Too expensive');
      await tester.tap(find.text('Main Wallet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(find.text(Strings.expenseWalletInsufficient), findsOneWidget);
      expect(repository.created, isEmpty);
    });

    testWidgets('spending the balance down to exactly zero is allowed', (
      tester,
    ) async {
      final repository = await openForm(tester);

      await fillAmount(tester, '1000');
      await fillDescription(tester, 'Exactly enough');
      await tester.tap(find.text('Main Wallet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));
    });
  });

  group('hardening', () {
    testWidgets('the save button becomes unpressable while in flight', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository();
      repository.gate = Completer<void>();

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await fillAmount(tester, '99');
      await fillDescription(tester, 'Snack');

      await tester.tap(find.text('Save expense'));
      await tester.pump();

      expect(find.text('Save expense'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      repository.gate!.complete();
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));
    });

    testWidgets('a failure surfaces a message and keeps the form open', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = RecordingExpenseRepository(
        createError: const ServerFailure('boom'),
      );

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await fillAmount(tester, '99');
      await fillDescription(tester, 'Snack');
      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();

      expect(find.text('boom'), findsOneWidget);
      expect(find.text('Add expense'), findsOneWidget);
    });
  });
}
