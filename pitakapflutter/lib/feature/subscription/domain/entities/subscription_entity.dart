import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/utils/date_utils.dart';

class SubscriptionEntity {
  final String id;
  final String userId;
  final String name;
  final String category;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final DateTime firstBillDate;
  final int reminderDaysBefore;
  final String colorHex;
  final String iconKey;
  final String notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.amount,
    required this.firstBillDate,
    this.billingCycle = BillingCycle.monthly,
    this.currency = Constants.defaultCurrency,
    this.reminderDaysBefore = Constants.defaultReminderDaysBefore,
    this.colorHex = '',
    this.iconKey = 'other',
    this.notes = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  DateTime nextDueDateAsOf(DateTime from) {
    return nextDueDate(
      firstBillDate: firstBillDate,
      billingCycle: billingCycle,
      from: from,
    );
  }

  int daysUntilNextDueAsOf(DateTime from) {
    return daysBetween(from, nextDueDateAsOf(from));
  }

  List<DateTime> upcomingDueDatesAsOf(DateTime from, {int count = 3}) {
    return upcomingDueDates(
      firstBillDate: firstBillDate,
      billingCycle: billingCycle,
      from: from,
      count: count,
    );
  }

  DateTime get nextDue => nextDueDateAsOf(DateTime.now());

  int get daysUntilNextDue => daysUntilNextDueAsOf(DateTime.now());

  double get yearlyCost => amount * billingCycle.periodsPerYear;

  double get monthlyCost => yearlyCost / 12;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SubscriptionEntity &&
            other.id == id &&
            other.userId == userId &&
            other.name == name &&
            other.category == category &&
            other.amount == amount &&
            other.currency == currency &&
            other.billingCycle == billingCycle &&
            other.firstBillDate == firstBillDate &&
            other.reminderDaysBefore == reminderDaysBefore &&
            other.colorHex == colorHex &&
            other.iconKey == iconKey &&
            other.notes == notes &&
            other.isActive == isActive &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    name,
    category,
    amount,
    currency,
    billingCycle,
    firstBillDate,
    reminderDaysBefore,
    colorHex,
    iconKey,
    notes,
    isActive,
    createdAt,
    updatedAt,
  ]);
}
