import 'package:pitakapflutter/core/utils/date_utils.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';

class WatchExpensesForDayParams {
  final String userId;
  final DateTime day;

  WatchExpensesForDayParams({required this.userId, required DateTime day})
    : day = startOfDay(day);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WatchExpensesForDayParams &&
            other.userId == userId &&
            other.day == day;
  }

  @override
  int get hashCode => Object.hash(userId, day);
}

class WatchExpensesForDayUseCase {
  final ExpenseRepository repository;

  const WatchExpensesForDayUseCase(this.repository);

  Stream<List<ExpenseEntity>> call(WatchExpensesForDayParams params) {
    return repository.watchExpensesForDay(params);
  }
}
