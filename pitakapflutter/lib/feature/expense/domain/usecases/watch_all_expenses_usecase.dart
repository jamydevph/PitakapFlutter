import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';

class WatchAllExpensesUseCase {
  final ExpenseRepository repository;

  const WatchAllExpensesUseCase(this.repository);

  Stream<List<ExpenseEntity>> call(String userId) {
    return repository.watchAllExpenses(userId);
  }
}
