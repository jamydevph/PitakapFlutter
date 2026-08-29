import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/keys.dart';
import 'package:pitakapflutter/core/utils/billing_date_utils.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.userId,
    required super.description,
    required super.category,
    required super.amount,
    required super.date,
    super.currency,
    super.paymentMethod,
    super.createdAt,
    super.updatedAt,
  });

  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      userId: entity.userId,
      description: entity.description,
      category: entity.category,
      amount: entity.amount,
      date: entity.date,
      currency: entity.currency,
      paymentMethod: entity.paymentMethod,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ExpenseModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ExpenseModel.fromMap(doc.id, doc.data());
  }

  factory ExpenseModel.fromMap(String id, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};

    return ExpenseModel(
      id: id,
      userId: map[Keys.userId] as String? ?? '',
      description: map[Keys.description] as String? ?? '',
      category: map[Keys.category] as String? ?? 'other',
      amount: (map[Keys.amount] as num?)?.toDouble() ?? 0,
      currency: map[Keys.currency] as String? ?? Constants.defaultCurrency,
      paymentMethod: map[Keys.paymentMethod] as String? ?? '',
      date: (map[Keys.date] as Timestamp?)?.toDate() ?? DateTime(1970),
      createdAt: (map[Keys.createdAt] as Timestamp?)?.toDate(),
      updatedAt: (map[Keys.updatedAt] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() => {
    Keys.userId: userId,
    ..._writableFields,
    Keys.createdAt: FieldValue.serverTimestamp(),
    Keys.updatedAt: FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toUpdateMap() => {
    ..._writableFields,
    Keys.updatedAt: FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toRestoreMap() => {
    Keys.userId: userId,
    ..._writableFields,
    Keys.createdAt: createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
    Keys.updatedAt: FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> get _writableFields => {
    Keys.description: description,
    Keys.category: category,
    Keys.amount: amount,
    Keys.currency: currency,
    Keys.paymentMethod: paymentMethod,
    Keys.date: Timestamp.fromDate(startOfDay(date)),
  };
}
