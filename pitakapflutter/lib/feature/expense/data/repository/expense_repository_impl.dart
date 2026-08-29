import 'package:pitakapflutter/feature/expense/data/datasources/expense_remote_datasource.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/restore_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/update_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDatasource remote;

  const ExpenseRepositoryImpl(this.remote);

  @override
  Stream<List<ExpenseEntity>> watchExpensesForDay(
    WatchExpensesForDayParams params,
  ) {
    return remote.watchExpensesForDay(params);
  }

  @override
  Stream<List<ExpenseEntity>> watchExpensesForMonth(
    WatchExpensesForMonthParams params,
  ) {
    return remote.watchExpensesForMonth(params);
  }

  @override
  Future<void> createExpense(CreateExpenseUseCaseParams params) {
    return remote.createExpense(params);
  }

  @override
  Future<void> updateExpense(UpdateExpenseUseCaseParams params) {
    return remote.updateExpense(params);
  }

  @override
  Future<void> deleteExpense(DeleteExpenseUseCaseParams params) {
    return remote.deleteExpense(params);
  }

  @override
  Future<void> restoreExpense(RestoreExpenseUseCaseParams params) {
    return remote.restoreExpense(params.expense);
  }
}
