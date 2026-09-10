import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/usecase/usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';

class CreateExpenseUseCaseParams {
  final String userId;
  final String description;
  final String category;
  final double amount;
  final DateTime date;
  final String currency;
  final String paymentMethod;
  final String walletId;

  const CreateExpenseUseCaseParams({
    required this.userId,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    this.currency = Constants.defaultCurrency,
    this.paymentMethod = '',
    this.walletId = '',
  });
}

class CreateExpenseUseCase
    implements UseCaseWithParams<void, CreateExpenseUseCaseParams> {
  final ExpenseRepository repository;

  const CreateExpenseUseCase(this.repository);

  @override
  Future<void> call(CreateExpenseUseCaseParams params) {
    return repository.createExpense(params);
  }
}
