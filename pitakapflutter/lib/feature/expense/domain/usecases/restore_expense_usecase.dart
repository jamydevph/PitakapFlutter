import 'package:pitakapflutter/core/usecase/usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';

class RestoreExpenseUseCaseParams {
  final ExpenseEntity expense;

  const RestoreExpenseUseCaseParams(this.expense);
}

class RestoreExpenseUseCase
    implements UseCaseWithParams<void, RestoreExpenseUseCaseParams> {
  final ExpenseRepository repository;

  const RestoreExpenseUseCase(this.repository);

  @override
  Future<void> call(RestoreExpenseUseCaseParams params) {
    return repository.restoreExpense(params);
  }
}
