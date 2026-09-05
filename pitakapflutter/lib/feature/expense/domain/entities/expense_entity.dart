import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/utils/date_utils.dart';

class ExpenseEntity {
  final String id;
  final String userId;
  final String description;
  final String category;
  final double amount;
  final String currency;
  final String paymentMethod;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseEntity({
    required this.id,
    required this.userId,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    this.currency = Constants.defaultCurrency,
    this.paymentMethod = '',
    this.createdAt,
    this.updatedAt,
  });

  DateTime get day => startOfDay(date);

  bool get hasPaymentMethod => paymentMethod.isNotEmpty;

  bool belongsTo(DateTime other) => isSameDay(date, other);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExpenseEntity &&
            other.id == id &&
            other.userId == userId &&
            other.description == description &&
            other.category == category &&
            other.amount == amount &&
            other.currency == currency &&
            other.paymentMethod == paymentMethod &&
            other.date == date &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    description,
    category,
    amount,
    currency,
    paymentMethod,
    date,
    createdAt,
    updatedAt,
  ]);
}
