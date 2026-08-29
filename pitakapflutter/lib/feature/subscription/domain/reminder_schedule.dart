import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/utils/billing_date_utils.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';

const int reminderHourOfDay = 9;

const int reminderIdMask = 0x3FFFFFFF;

int reminderIdFor(String subscriptionId) {
  var hash = 0;

  for (final unit in subscriptionId.codeUnits) {
    hash = (hash * 31 + unit) & reminderIdMask;
  }

  return hash;
}

String reminderBodyFor({required String name, required int daysBefore}) {
  if (daysBefore <= 0) return '$name ${Strings.reminderRenewsToday}';

  if (daysBefore == 1) return '$name ${Strings.reminderRenewsTomorrow}';

  return '$name ${Strings.reminderRenewsIn} $daysBefore '
      '${Strings.reminderDaysSuffix}';
}

DateTime reminderTimeFor({
  required DateTime dueDate,
  required int daysBefore,
  int hour = reminderHourOfDay,
}) {
  final day = startOfDay(dueDate);

  return DateTime(day.year, day.month, day.day - daysBefore, hour);
}

class ScheduledReminder {
  final int id;
  final String subscriptionId;
  final DateTime fireAt;
  final DateTime dueDate;

  const ScheduledReminder({
    required this.id,
    required this.subscriptionId,
    required this.fireAt,
    required this.dueDate,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ScheduledReminder &&
            other.id == id &&
            other.subscriptionId == subscriptionId &&
            other.fireAt == fireAt &&
            other.dueDate == dueDate;
  }

  @override
  int get hashCode => Object.hash(id, subscriptionId, fireAt, dueDate);
}

const int reminderMaxCycleLookahead = 64;

ScheduledReminder? reminderFor(
  SubscriptionEntity subscription, {
  required DateTime now,
  int hour = reminderHourOfDay,
}) {
  if (!subscription.isActive) return null;

  var dueDate = subscription.nextDueDateAsOf(now);

  for (var attempt = 0; attempt < reminderMaxCycleLookahead; attempt++) {
    final fireAt = reminderTimeFor(
      dueDate: dueDate,
      daysBefore: subscription.reminderDaysBefore,
      hour: hour,
    );

    if (fireAt.isAfter(now)) {
      return ScheduledReminder(
        id: reminderIdFor(subscription.id),
        subscriptionId: subscription.id,
        fireAt: fireAt,
        dueDate: dueDate,
      );
    }

    dueDate = subscription.nextDueDateAsOf(
      DateTime(dueDate.year, dueDate.month, dueDate.day + 1),
    );
  }

  return null;
}
