import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/utils/date_utils.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';

ExpenseEntity expense({
  String id = 'exp-1',
  String description = 'Lunch at Jollibee',
  String category = 'food',
  double amount = 250,
  String paymentMethod = '',
  DateTime? date,
}) {
  return ExpenseEntity(
    id: id,
    userId: 'uid-1',
    description: description,
    category: category,
    amount: amount,
    paymentMethod: paymentMethod,
    date: date ?? DateTime(2026, 8, 15),
  );
}

void main() {
  group('defaults', () {
    test('currency defaults to the app currency', () {
      expect(expense().currency, Constants.defaultCurrency);
    });

    test('payment method is optional and empty by default', () {
      expect(expense().paymentMethod, isEmpty);
      expect(expense().hasPaymentMethod, isFalse);
      expect(expense(paymentMethod: 'gcash').hasPaymentMethod, isTrue);
    });

    test('timestamps are null until Firestore fills them', () {
      expect(expense().createdAt, isNull);
      expect(expense().updatedAt, isNull);
    });
  });

  group('day normalisation', () {
    test('a late-evening expense still belongs to that same day', () {
      final lateNight = expense(date: DateTime(2026, 8, 15, 23, 59, 59));

      expect(lateNight.day, DateTime(2026, 8, 15));
    });

    test('one minute later is the next day, not the same one', () {
      final justAfter = expense(date: DateTime(2026, 8, 16, 0, 0, 1));

      expect(justAfter.day, DateTime(2026, 8, 16));
      expect(justAfter.day, isNot(DateTime(2026, 8, 15)));
    });

    test('midnight exactly belongs to the day it starts', () {
      final midnight = expense(date: DateTime(2026, 8, 15));

      expect(midnight.day, DateTime(2026, 8, 15));
    });

    test('the normalised day stays local, never UTC', () {
      final evening = expense(date: DateTime(2026, 8, 15, 22));

      expect(evening.day.isUtc, isFalse);
      expect(evening.day.hour, 0);
    });

    test('belongsTo ignores the time of day on both sides', () {
      final lunch = expense(date: DateTime(2026, 8, 15, 12, 30));

      expect(lunch.belongsTo(DateTime(2026, 8, 15)), isTrue);
      expect(lunch.belongsTo(DateTime(2026, 8, 15, 23, 59)), isTrue);
      expect(lunch.belongsTo(DateTime(2026, 8, 16)), isFalse);
      expect(lunch.belongsTo(DateTime(2026, 8, 14, 23, 59)), isFalse);
    });

    test('reuses the shared startOfDay rather than its own arithmetic', () {
      final value = DateTime(2026, 8, 15, 17, 45);

      expect(expense(date: value).day, startOfDay(value));
    });
  });

  group('value equality', () {
    test('two expenses with the same fields are equal', () {
      expect(expense(), expense());
      expect(expense().hashCode, expense().hashCode);
    });

    test('a different amount is a different expense', () {
      expect(expense(amount: 250), isNot(expense(amount: 251)));
    });

    test('the same day at a different time is a different expense', () {
      expect(
        expense(date: DateTime(2026, 8, 15, 9)),
        isNot(expense(date: DateTime(2026, 8, 15, 10))),
      );
    });
  });
}
