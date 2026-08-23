import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pitakapflutter/core/error/firestore_error_mapper.dart';
import 'package:pitakapflutter/core/resources/keys.dart';
import 'package:pitakapflutter/feature/expense/data/model/expense_model.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/update_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';

abstract interface class ExpenseRemoteDatasource {
  Stream<List<ExpenseModel>> watchExpensesForDay(
    WatchExpensesForDayParams params,
  );

  Stream<List<ExpenseModel>> watchExpensesForMonth(
    WatchExpensesForMonthParams params,
  );

  Future<void> createExpense(CreateExpenseUseCaseParams params);

  Future<void> updateExpense(UpdateExpenseUseCaseParams params);

  Future<void> deleteExpense(DeleteExpenseUseCaseParams params);
}

class ExpenseRemoteDatasourceImpl implements ExpenseRemoteDatasource {
  final FirebaseFirestore firestore;

  const ExpenseRemoteDatasourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _collection {
    return firestore.collection(Keys.expensesCollection);
  }

  @override
  Stream<List<ExpenseModel>> watchExpensesForDay(
    WatchExpensesForDayParams params,
  ) {
    return _collection
        .where(Keys.userId, isEqualTo: params.userId)
        .where(Keys.date, isEqualTo: Timestamp.fromDate(params.day))
        .snapshots()
        .map(_toSortedModels)
        .handleError((Object error) => throw FirestoreErrorMapper.from(error));
  }

  @override
  Stream<List<ExpenseModel>> watchExpensesForMonth(
    WatchExpensesForMonthParams params,
  ) {
    return _collection
        .where(Keys.userId, isEqualTo: params.userId)
        .where(
          Keys.date,
          isGreaterThanOrEqualTo: Timestamp.fromDate(params.month),
        )
        .where(Keys.date, isLessThan: Timestamp.fromDate(params.nextMonth))
        .snapshots()
        .map(_toSortedModels)
        .handleError((Object error) => throw FirestoreErrorMapper.from(error));
  }

  @override
  Future<void> createExpense(CreateExpenseUseCaseParams params) async {
    try {
      final model = ExpenseModel(
        id: '',
        userId: params.userId,
        description: params.description,
        category: params.category,
        amount: params.amount,
        date: params.date,
        currency: params.currency,
        paymentMethod: params.paymentMethod,
      );

      await _collection.add(model.toCreateMap());
    } catch (error) {
      throw FirestoreErrorMapper.from(error);
    }
  }

  @override
  Future<void> updateExpense(UpdateExpenseUseCaseParams params) async {
    try {
      final model = ExpenseModel.fromEntity(params.expense);

      await _collection.doc(model.id).update(model.toUpdateMap());
    } catch (error) {
      throw FirestoreErrorMapper.from(error);
    }
  }

  @override
  Future<void> deleteExpense(DeleteExpenseUseCaseParams params) async {
    try {
      await _collection.doc(params.expenseId).delete();
    } catch (error) {
      throw FirestoreErrorMapper.from(error);
    }
  }

  List<ExpenseModel> _toSortedModels(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map(ExpenseModel.fromDoc).toList()..sort(compareNewest);
  }
}

int compareNewest(ExpenseModel a, ExpenseModel b) {
  final left = a.createdAt;
  final right = b.createdAt;

  if (left == null && right == null) return a.id.compareTo(b.id);
  if (left == null) return -1;
  if (right == null) return 1;

  final byTime = right.compareTo(left);

  return byTime != 0 ? byTime : a.id.compareTo(b.id);
}
