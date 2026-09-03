import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/restore_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/update_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

final lunch = ExpenseEntity(
  id: 'exp-1',
  userId: 'uid-1',
  description: 'Lunch at Jollibee',
  category: 'food',
  amount: 250,
  date: DateTime(2026, 8, 15),
);

void main() {
  late MockExpenseRepository repository;

  setUpAll(() {
    registerFallbackValue(
      CreateExpenseUseCaseParams(
        userId: '',
        description: '',
        category: '',
        amount: 0,
        date: DateTime(2026),
      ),
    );
    registerFallbackValue(UpdateExpenseUseCaseParams(lunch));
    registerFallbackValue(const DeleteExpenseUseCaseParams(''));
    registerFallbackValue(
      WatchExpensesForDayParams(userId: '', day: DateTime(2026)),
    );
    registerFallbackValue(RestoreExpenseUseCaseParams(lunch));
    registerFallbackValue(
      WatchExpensesForMonthParams(userId: '', month: DateTime(2026)),
    );
  });

  setUp(() => repository = MockExpenseRepository());

  group('WatchExpensesForDayUseCase', () {
    test('returns the stream the repository exposes', () {
      when(
        () => repository.watchExpensesForDay(any()),
      ).thenAnswer((_) => Stream.value([lunch]));

      final stream = WatchExpensesForDayUseCase(
        repository,
      ).call(WatchExpensesForDayParams(userId: 'uid-1', day: DateTime(2026, 8, 15)));

      expect(stream, emits([lunch]));
    });

    test('normalises the requested day so a time of day cannot leak into '
        'the query', () {
      final params = WatchExpensesForDayParams(
        userId: 'uid-1',
        day: DateTime(2026, 8, 15, 23, 59, 59),
      );

      expect(params.day, DateTime(2026, 8, 15));
    });

    test('two params for the same day are equal, so the provider family '
        'does not create a second stream', () {
      final morning = WatchExpensesForDayParams(
        userId: 'uid-1',
        day: DateTime(2026, 8, 15, 8),
      );
      final evening = WatchExpensesForDayParams(
        userId: 'uid-1',
        day: DateTime(2026, 8, 15, 20),
      );

      expect(morning, evening);
      expect(morning.hashCode, evening.hashCode);
    });

    test('a different user on the same day is a different key', () {
      expect(
        WatchExpensesForDayParams(userId: 'uid-1', day: DateTime(2026, 8, 15)),
        isNot(
          WatchExpensesForDayParams(
            userId: 'uid-2',
            day: DateTime(2026, 8, 15),
          ),
        ),
      );
    });

    test('surfaces a repository stream error unchanged', () {
      when(() => repository.watchExpensesForDay(any())).thenAnswer(
        (_) => Stream.error(const NetworkFailure('No internet connection')),
      );

      final stream = WatchExpensesForDayUseCase(
        repository,
      ).call(WatchExpensesForDayParams(userId: 'uid-1', day: DateTime(2026)));

      expect(stream, emitsError(isA<NetworkFailure>()));
    });
  });

  group('CreateExpenseUseCase', () {
    test('passes the params straight through', () async {
      when(() => repository.createExpense(any())).thenAnswer((_) async {});

      final params = CreateExpenseUseCaseParams(
        userId: 'uid-1',
        description: 'Grab to BGC',
        category: 'transport',
        amount: 215,
        date: DateTime(2026, 8, 15),
      );

      await CreateExpenseUseCase(repository).call(params);

      verify(() => repository.createExpense(params)).called(1);
    });

    test('defaults currency and leaves payment method unset', () {
      final params = CreateExpenseUseCaseParams(
        userId: 'uid-1',
        description: 'Milk tea',
        category: 'food',
        amount: 150,
        date: DateTime(2026, 8, 15),
      );

      expect(params.currency, 'PHP');
      expect(params.paymentMethod, isEmpty);
    });

    test('propagates a failure rather than swallowing it', () {
      when(
        () => repository.createExpense(any()),
      ).thenThrow(const NetworkFailure('No internet connection'));

      expect(
        () => CreateExpenseUseCase(repository).call(
          CreateExpenseUseCaseParams(
            userId: 'uid-1',
            description: '',
            category: 'food',
            amount: 1,
            date: DateTime(2026),
          ),
        ),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('UpdateExpenseUseCase', () {
    test('carries the whole entity', () async {
      when(() => repository.updateExpense(any())).thenAnswer((_) async {});

      await UpdateExpenseUseCase(
        repository,
      ).call(UpdateExpenseUseCaseParams(lunch));

      final captured =
          verify(() => repository.updateExpense(captureAny())).captured.single
              as UpdateExpenseUseCaseParams;

      expect(captured.expense, lunch);
    });
  });

  group('DeleteExpenseUseCase', () {
    test('carries only the id', () async {
      when(() => repository.deleteExpense(any())).thenAnswer((_) async {});

      await DeleteExpenseUseCase(
        repository,
      ).call(const DeleteExpenseUseCaseParams('exp-1'));

      final captured =
          verify(() => repository.deleteExpense(captureAny())).captured.single
              as DeleteExpenseUseCaseParams;

      expect(captured.expenseId, 'exp-1');
    });
  });

  group('RestoreExpenseUseCase', () {
    final params = RestoreExpenseUseCaseParams(lunch);

    test('delegates to the repository with the whole entity', () async {
      when(() => repository.restoreExpense(any())).thenAnswer((_) async {});

      await RestoreExpenseUseCase(repository).call(params);

      verify(() => repository.restoreExpense(params)).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('⭐ restore is NOT create — the document id must be carried', () async {
      when(() => repository.restoreExpense(any())).thenAnswer((_) async {});

      await RestoreExpenseUseCase(repository).call(params);

      final restored = (verify(
        () => repository.restoreExpense(captureAny()),
      ).captured.single as RestoreExpenseUseCaseParams).expense;

      expect(restored.id, 'exp-1');
      verifyNever(() => repository.createExpense(any()));
    });

    test('⭐ the original date is preserved, not reset to today', () async {
      when(() => repository.restoreExpense(any())).thenAnswer((_) async {});

      await RestoreExpenseUseCase(repository).call(params);

      final restored = (verify(
        () => repository.restoreExpense(captureAny()),
      ).captured.single as RestoreExpenseUseCaseParams).expense;

      expect(restored.date, DateTime(2026, 8, 15));
      expect(restored.description, 'Lunch at Jollibee');
      expect(restored.amount, 250);
    });

    test('lets failures propagate', () {
      when(() => repository.restoreExpense(any()))
          .thenThrow(const ServerFailure('That record no longer exists'));

      expect(
        () => RestoreExpenseUseCase(repository).call(params),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('WatchExpensesForMonthUseCase', () {
    test('returns the stream the repository exposes', () {
      when(
        () => repository.watchExpensesForMonth(any()),
      ).thenAnswer((_) => Stream.value([lunch]));

      final params = WatchExpensesForMonthParams(
        userId: 'uid-1',
        month: DateTime(2026, 8),
      );

      expect(
        WatchExpensesForMonthUseCase(repository).call(params),
        emits([lunch]),
      );
      verify(() => repository.watchExpensesForMonth(params)).called(1);
    });

    test('⭐ any day within a month normalises to the first of it', () {
      final fromMidMonth = WatchExpensesForMonthParams(
        userId: 'uid-1',
        month: DateTime(2026, 8, 27, 23, 59, 59),
      );

      expect(fromMidMonth.month, DateTime(2026, 8));
    });

    test('⭐ nextMonth is the exclusive upper bound of the range query', () {
      final august = WatchExpensesForMonthParams(
        userId: 'uid-1',
        month: DateTime(2026, 8, 15),
      );

      expect(august.nextMonth, DateTime(2026, 9));
    });

    test('⭐ December rolls the YEAR, not just the month', () {
      final december = WatchExpensesForMonthParams(
        userId: 'uid-1',
        month: DateTime(2026, 12, 25),
      );

      expect(december.month, DateTime(2026, 12));
      expect(december.nextMonth, DateTime(2027));
    });

    test('⭐ two params for the same month are equal, so the provider family '
        'does not open a second subscription', () {
      final a = WatchExpensesForMonthParams(
        userId: 'uid-1',
        month: DateTime(2026, 8, 1),
      );
      final b = WatchExpensesForMonthParams(
        userId: 'uid-1',
        month: DateTime(2026, 8, 27, 14, 30),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different user on the same month is a different key', () {
      final mine = WatchExpensesForMonthParams(
        userId: 'uid-1',
        month: DateTime(2026, 8),
      );
      final theirs = WatchExpensesForMonthParams(
        userId: 'uid-2',
        month: DateTime(2026, 8),
      );

      expect(mine, isNot(theirs));
    });

    test('surfaces a repository stream error unchanged', () {
      when(() => repository.watchExpensesForMonth(any())).thenAnswer(
        (_) => Stream.error(const ServerFailure('The query needs an index')),
      );

      expect(
        WatchExpensesForMonthUseCase(repository).call(
          WatchExpensesForMonthParams(userId: 'uid-1', month: DateTime(2026, 8)),
        ),
        emitsError(isA<ServerFailure>()),
      );
    });
  });
}
