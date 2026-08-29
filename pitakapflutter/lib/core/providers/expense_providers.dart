import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/feature/expense/data/datasources/expense_remote_datasource.dart';
import 'package:pitakapflutter/feature/expense/data/repository/expense_repository_impl.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/restore_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/update_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';

final expenseRemoteDatasourceProvider = Provider<ExpenseRemoteDatasource>(
  (ref) => ExpenseRemoteDatasourceImpl(firestore: ref.watch(firestoreProvider)),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepositoryImpl(ref.watch(expenseRemoteDatasourceProvider)),
);

final watchExpensesForDayUseCaseProvider = Provider<WatchExpensesForDayUseCase>(
  (ref) => WatchExpensesForDayUseCase(ref.watch(expenseRepositoryProvider)),
);

final createExpenseUseCaseProvider = Provider<CreateExpenseUseCase>(
  (ref) => CreateExpenseUseCase(ref.watch(expenseRepositoryProvider)),
);

final updateExpenseUseCaseProvider = Provider<UpdateExpenseUseCase>(
  (ref) => UpdateExpenseUseCase(ref.watch(expenseRepositoryProvider)),
);

final deleteExpenseUseCaseProvider = Provider<DeleteExpenseUseCase>(
  (ref) => DeleteExpenseUseCase(ref.watch(expenseRepositoryProvider)),
);

final restoreExpenseUseCaseProvider = Provider<RestoreExpenseUseCase>(
  (ref) => RestoreExpenseUseCase(ref.watch(expenseRepositoryProvider)),
);

final expensesForDayStreamProvider =
    StreamProvider.family<List<ExpenseEntity>, WatchExpensesForDayParams>(
      (ref, params) =>
          ref.watch(watchExpensesForDayUseCaseProvider).call(params),
    );

final watchExpensesForMonthUseCaseProvider =
    Provider<WatchExpensesForMonthUseCase>(
      (ref) =>
          WatchExpensesForMonthUseCase(ref.watch(expenseRepositoryProvider)),
    );

final expensesForMonthStreamProvider =
    StreamProvider.family<List<ExpenseEntity>, WatchExpensesForMonthParams>(
      (ref, params) =>
          ref.watch(watchExpensesForMonthUseCaseProvider).call(params),
    );
