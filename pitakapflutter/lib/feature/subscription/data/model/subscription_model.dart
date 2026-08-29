import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/keys.dart';
import 'package:pitakapflutter/core/utils/billing_date_utils.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.category,
    required super.amount,
    required super.firstBillDate,
    super.billingCycle,
    super.currency,
    super.reminderDaysBefore,
    super.colorHex,
    super.iconKey,
    super.notes,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  factory SubscriptionModel.fromEntity(SubscriptionEntity entity) {
    return SubscriptionModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      category: entity.category,
      amount: entity.amount,
      firstBillDate: entity.firstBillDate,
      billingCycle: entity.billingCycle,
      currency: entity.currency,
      reminderDaysBefore: entity.reminderDaysBefore,
      colorHex: entity.colorHex,
      iconKey: entity.iconKey,
      notes: entity.notes,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory SubscriptionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return SubscriptionModel.fromMap(doc.id, doc.data());
  }

  factory SubscriptionModel.fromMap(String id, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};

    return SubscriptionModel(
      id: id,
      userId: map[Keys.userId] as String? ?? '',
      name: map[Keys.name] as String? ?? '',
      category: map[Keys.category] as String? ?? 'other',
      amount: (map[Keys.amount] as num?)?.toDouble() ?? 0,
      currency: map[Keys.currency] as String? ?? Constants.defaultCurrency,
      billingCycle: BillingCycle.fromWire(map[Keys.billingCycle] as String?),
      firstBillDate:
          (map[Keys.firstBillDate] as Timestamp?)?.toDate() ?? DateTime(1970),
      reminderDaysBefore:
          (map[Keys.reminderDaysBefore] as num?)?.toInt() ??
          Constants.defaultReminderDaysBefore,
      colorHex: map[Keys.colorHex] as String? ?? '',
      iconKey: map[Keys.iconKey] as String? ?? 'other',
      notes: map[Keys.notes] as String? ?? '',
      isActive: map[Keys.isActive] as bool? ?? true,
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
    Keys.name: name,
    Keys.category: category,
    Keys.amount: amount,
    Keys.currency: currency,
    Keys.billingCycle: billingCycle.wireValue,
    Keys.firstBillDate: Timestamp.fromDate(startOfDay(firstBillDate)),
    Keys.reminderDaysBefore: reminderDaysBefore,
    Keys.colorHex: colorHex,
    Keys.iconKey: iconKey,
    Keys.notes: notes,
    Keys.isActive: isActive,
  };
}
