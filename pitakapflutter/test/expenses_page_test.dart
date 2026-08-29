import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/utils/billing_date_utils.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/restore_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/update_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';
import 'package:pitakapflutter/feature/expense/presentation/providers/selected_day_controller.dart';

import 'helpers.dart';

class FakeExpenseRepository implements ExpenseRepository {
  final Map<DateTime, List<ExpenseEntity>> _byDay;
  final Object? error;

  final List<String> deleted = [];
  final List<CreateExpenseUseCaseParams> created = [];
  final List<ExpenseEntity> restored = [];

  final Map<DateTime, StreamController<List<ExpenseEntity>>> _controllers = {};

  FakeExpenseRepository({
    Map<DateTime, List<ExpenseEntity>>? byDay,
    this.error,
  }) : _byDay = {
         for (final entry in (byDay ?? const {}).entries)
           entry.key: List.of(entry.value),
       };

  @override
  Stream<List<ExpenseEntity>> watchExpensesForDay(
    WatchExpensesForDayParams params,
  ) {
    if (error != null) return Stream.error(error!);

    final controller = _controllers.putIfAbsent(params.day, () {
      final created = StreamController<List<ExpenseEntity>>();
      created.add(List.of(_byDay[params.day] ?? const []));
      return created;
    });

    return controller.stream;
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
  }

  @override
  Future<void> updateExpense(UpdateExpenseUseCaseParams params) async {}

  @override
  Future<void> restoreExpense(RestoreExpenseUseCaseParams params) async {
    restored.add(params.expense);

    final day = startOfDay(params.expense.date);
    _byDay.putIfAbsent(day, () => []).add(params.expense);

    _controllers[day]?.add(List.of(_byDay[day] ?? const []));
  }

  @override
  Future<void> deleteExpense(DeleteExpenseUseCaseParams params) async {
    deleted.add(params.expenseId);

    for (final entry in _byDay.entries) {
      entry.value.removeWhere((expense) => expense.id == params.expenseId);
    }

    for (final entry in _controllers.entries) {
      entry.value.add(List.of(_byDay[entry.key] ?? const []));
    }
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}

ExpenseEntity expense({
  required String id,
  required String description,
  required DateTime date,
  String category = 'food',
  double amount = 250,
  String paymentMethod = 'cash',
}) {
  return ExpenseEntity(
    id: id,
    userId: 'uid-1',
    description: description,
    category: category,
    amount: amount,
    paymentMethod: paymentMethod,
    date: date,
  );
}

void main() {
  final today = startOfDay(DateTime.now());
  final yesterday = DateTime(today.year, today.month, today.day - 1);

  void sizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  FakeExpenseRepository repositoryWith(
    Map<DateTime, List<ExpenseEntity>> byDay,
  ) {
    final repository = FakeExpenseRepository(byDay: byDay);
    addTearDown(repository.dispose);
    return repository;
  }

  group('ExpensesPage', () {
    testWidgets('shows the day total and entry count for today', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = repositoryWith({
        today: [
          expense(id: 'e1', description: 'Lunch at Jollibee', date: today),
          expense(
            id: 'e2',
            description: 'Grab to BGC',
            date: today,
            category: 'transport',
            amount: 320,
            paymentMethod: 'gcash',
          ),
        ],
      });

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      expect(find.text('₱570.00'), findsOneWidget);
      expect(find.text('2 entries'), findsOneWidget);
      expect(find.text('Lunch at Jollibee'), findsOneWidget);
      expect(find.text('Grab to BGC'), findsOneWidget);
      expect(find.text('-₱320.00'), findsOneWidget);
      expect(find.text('Transport · GCash'), findsOneWidget);
    });

    testWidgets('nudges logging when today has nothing', (tester) async {
      sizeViewport(tester);

      final repository = repositoryWith({});

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      expect(find.text('Log your first expense for today.'), findsOneWidget);
      expect(find.text('₱0.00'), findsOneWidget);
      expect(find.text('0 entries'), findsOneWidget);
    });

    testWidgets('a past day with nothing does not claim it is today', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = repositoryWith({});

      final container = await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      container.read(selectedDayProvider.notifier).select(yesterday);
      await tester.pumpAndSettle();

      expect(
        find.text('You did not record any spending on this day.'),
        findsOneWidget,
      );
      expect(find.text('Log your first expense for today.'), findsNothing);
    });

    testWidgets('tapping a day in the strip switches the stream', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = repositoryWith({
        today: [
          expense(id: 'e1', description: 'Lunch at Jollibee', date: today),
        ],
        yesterday: [
          expense(
            id: 'e2',
            description: 'Groceries at SM',
            date: yesterday,
            category: 'groceries',
            amount: 515,
          ),
        ],
      });

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      expect(find.text('Lunch at Jollibee'), findsOneWidget);

      await tester.tap(find.text('${yesterday.day}'));
      await tester.pumpAndSettle();

      expect(find.text('Groceries at SM'), findsOneWidget);
      expect(find.text('Lunch at Jollibee'), findsNothing);
      expect(find.text('₱515.00'), findsOneWidget);
    });

    testWidgets('swiping an expense deletes it and offers undo', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = repositoryWith({
        today: [
          expense(id: 'e1', description: 'Lunch at Jollibee', date: today),
        ],
      });

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.drag(
        find.text('Lunch at Jollibee'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(repository.deleted, ['e1']);
      expect(find.text('Expense deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('⭐ undo restores the same document, it does not re-create', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = repositoryWith({
        today: [
          expense(
            id: 'e1',
            description: 'Milk tea',
            date: today,
            amount: 160,
            paymentMethod: 'gcash',
          ),
        ],
      });

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      await tester.drag(find.text('Milk tea'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(repository.restored, hasLength(1));
      expect(repository.created, isEmpty);

      final restored = repository.restored.single;
      expect(restored.id, 'e1');
      expect(restored.description, 'Milk tea');
      expect(restored.amount, 160);
      expect(restored.paymentMethod, 'gcash');
      expect(restored.date, today);
      expect(restored.userId, 'uid-1');
    });

    testWidgets('surfaces a load failure without leaking internals', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = FakeExpenseRepository(
        error: const ServerFailure('boom'),
      );
      addTearDown(repository.dispose);

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      expect(find.text('Could not load your expenses'), findsOneWidget);
    });

    testWidgets('offers a way to add an expense', (tester) async {
      sizeViewport(tester);

      final repository = repositoryWith({});

      await pumpAppAt(
        tester,
        AppRoutes.expenses,
        signedInUid: 'uid-1',
        expenseRepository: repository,
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });
  });
}
