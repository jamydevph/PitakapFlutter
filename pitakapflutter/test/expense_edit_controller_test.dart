import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/expense_providers.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/update_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';
import 'package:pitakapflutter/feature/expense/presentation/providers/expense_edit_controller.dart';
import 'package:pitakapflutter/feature/expense/presentation/providers/expense_edit_state.dart';

class GatedExpenseRepository implements ExpenseRepository {
  final Object? error;

  int createCalls = 0;
  int updateCalls = 0;
  Completer<void>? gate;

  GatedExpenseRepository({this.error});

  @override
  Stream<List<ExpenseEntity>> watchExpensesForDay(
    WatchExpensesForDayParams params,
  ) {
    return Stream.value(const []);
  }

  @override
  Stream<List<ExpenseEntity>> watchExpensesForMonth(
    WatchExpensesForMonthParams params,
  ) {
    return Stream.value(const []);
  }

  @override
  Future<void> createExpense(CreateExpenseUseCaseParams params) async {
    createCalls++;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }

  @override
  Future<void> updateExpense(UpdateExpenseUseCaseParams params) async {
    updateCalls++;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }

  @override
  Future<void> deleteExpense(DeleteExpenseUseCaseParams params) async {}
}

ProviderContainer containerWith(GatedExpenseRepository repository) {
  final container = ProviderContainer(
    overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

final params = CreateExpenseUseCaseParams(
  userId: 'uid-1',
  description: 'Lunch',
  category: 'food',
  amount: 250,
  date: DateTime(2026, 8, 19),
);

void main() {
  test('starts in the initial state', () {
    final container = containerWith(GatedExpenseRepository());

    expect(
      container.read(expenseEditControllerProvider).value,
      isA<ExpenseEditInitialState>(),
    );
  });

  test('a successful create reports it was not an existing expense', () async {
    final container = containerWith(GatedExpenseRepository());
    final controller = container.read(expenseEditControllerProvider.notifier);

    await controller.create(params);

    final state = container.read(expenseEditControllerProvider).value;
    expect(state, isA<ExpenseEditSuccessState>());
    expect((state as ExpenseEditSuccessState).wasExisting, isFalse);
  });

  test('a successful update reports it WAS an existing expense', () async {
    final container = containerWith(GatedExpenseRepository());
    final controller = container.read(expenseEditControllerProvider.notifier);

    await controller.updateExisting(
      ExpenseEntity(
        id: 'e1',
        userId: 'uid-1',
        description: 'Lunch',
        category: 'food',
        amount: 250,
        date: DateTime(2026, 8, 19),
      ),
    );

    final state = container.read(expenseEditControllerProvider).value;
    expect(state, isA<ExpenseEditSuccessState>());
    expect((state as ExpenseEditSuccessState).wasExisting, isTrue);
  });

  test('a failure surfaces a mapped message, never the raw error', () async {
    final container = containerWith(
      GatedExpenseRepository(error: const ServerFailure('boom')),
    );
    final controller = container.read(expenseEditControllerProvider.notifier);

    await controller.create(params);

    final state = container.read(expenseEditControllerProvider).value;
    expect(state, isA<ExpenseEditFailedState>());
    expect((state as ExpenseEditFailedState).message, 'boom');
  });

  test('a non-Failure error does not leak internals into the message', () async {
    final container = containerWith(
      GatedExpenseRepository(error: StateError('internal detail')),
    );
    final controller = container.read(expenseEditControllerProvider.notifier);

    await controller.create(params);

    final state = container.read(expenseEditControllerProvider).value;
    expect(state, isA<ExpenseEditFailedState>());
    expect(
      (state as ExpenseEditFailedState).message,
      'Something went wrong. Please try again.',
    );
  });

  test('⭐ a re-entrant create is dropped by the isBusy guard', () async {
    final repository = GatedExpenseRepository();
    repository.gate = Completer<void>();

    final container = containerWith(repository);
    final controller = container.read(expenseEditControllerProvider.notifier);

    final first = controller.create(params);
    final second = controller.create(params);

    expect(controller.isBusy, isTrue);

    repository.gate!.complete();
    await Future.wait([first, second]);

    expect(repository.createCalls, 1);
  });

  test('⭐ a re-entrant update is dropped by the same guard', () async {
    final repository = GatedExpenseRepository();
    repository.gate = Completer<void>();

    final container = containerWith(repository);
    final controller = container.read(expenseEditControllerProvider.notifier);

    final entity = ExpenseEntity(
      id: 'e1',
      userId: 'uid-1',
      description: 'Lunch',
      category: 'food',
      amount: 250,
      date: DateTime(2026, 8, 19),
    );

    final first = controller.updateExisting(entity);
    final second = controller.updateExisting(entity);

    repository.gate!.complete();
    await Future.wait([first, second]);

    expect(repository.updateCalls, 1);
  });

  test('reset returns to the initial state so the page can be reused', () async {
    final container = containerWith(GatedExpenseRepository());
    final controller = container.read(expenseEditControllerProvider.notifier);

    await controller.create(params);
    controller.reset();

    expect(
      container.read(expenseEditControllerProvider).value,
      isA<ExpenseEditInitialState>(),
    );
  });
}
