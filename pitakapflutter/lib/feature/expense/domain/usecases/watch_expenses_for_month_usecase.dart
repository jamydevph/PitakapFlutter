import 'package:pitakapflutter/core/utils/billing_date_utils.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';

class WatchExpensesForMonthParams {
  final String userId;
  final DateTime month;

  WatchExpensesForMonthParams({required this.userId, required DateTime month})
    : month = startOfMonth(month);

  DateTime get nextMonth => startOfNextMonth(month);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WatchExpensesForMonthParams &&
            other.userId == userId &&
            other.month == month;
  }

  @override
  int get hashCode => Object.hash(userId, month);
}

class WatchExpensesForMonthUseCase {
  final ExpenseRepository repository;

  const WatchExpensesForMonthUseCase(this.repository);

  Stream<List<ExpenseEntity>> call(WatchExpensesForMonthParams params) {
    return repository.watchExpensesForMonth(params);
  }
}
