import 'package:pitakapflutter/core/resources/billing_cycle.dart';

DateTime startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int daysBetween(DateTime from, DateTime to) {
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(to.year, to.month, to.day);

  return end.difference(start).inDays;
}

int daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

DateTime addMonths(DateTime anchor, int months) {
  final totalMonths = anchor.month - 1 + months;
  final year = anchor.year + (totalMonths / 12).floor();
  final month = totalMonths % 12 + 1;
  final lastDay = daysInMonth(year, month);

  return DateTime(year, month, anchor.day <= lastDay ? anchor.day : lastDay);
}

DateTime nextDueDate({
  required DateTime firstBillDate,
  required BillingCycle billingCycle,
  required DateTime from,
}) {
  final anchor = startOfDay(firstBillDate);
  final start = startOfDay(from);

  if (!start.isAfter(anchor)) return anchor;

  return switch (billingCycle) {
    BillingCycle.weekly => _nextWeekly(anchor, start),
    BillingCycle.monthly => _nextMonthly(anchor, start, 1),
    BillingCycle.quarterly => _nextMonthly(anchor, start, 3),
    BillingCycle.yearly => _nextMonthly(anchor, start, 12),
  };
}

List<DateTime> upcomingDueDates({
  required DateTime firstBillDate,
  required BillingCycle billingCycle,
  required DateTime from,
  int count = 3,
}) {
  final dates = <DateTime>[];
  var cursor = startOfDay(from);

  for (var index = 0; index < count; index++) {
    final due = nextDueDate(
      firstBillDate: firstBillDate,
      billingCycle: billingCycle,
      from: cursor,
    );
    dates.add(due);
    cursor = DateTime(due.year, due.month, due.day + 1);
  }

  return dates;
}

DateTime _nextWeekly(DateTime anchor, DateTime start) {
  var periods = daysBetween(anchor, start) ~/ 7;
  var candidate = DateTime(anchor.year, anchor.month, anchor.day + periods * 7);

  while (candidate.isBefore(start)) {
    periods++;
    candidate = DateTime(anchor.year, anchor.month, anchor.day + periods * 7);
  }

  return candidate;
}

DateTime _nextMonthly(DateTime anchor, DateTime start, int monthsPerCycle) {
  final elapsedMonths =
      (start.year - anchor.year) * 12 + (start.month - anchor.month);
  var periods = elapsedMonths ~/ monthsPerCycle;
  if (periods < 0) periods = 0;

  var candidate = addMonths(anchor, periods * monthsPerCycle);

  while (candidate.isBefore(start)) {
    periods++;
    candidate = addMonths(anchor, periods * monthsPerCycle);
  }

  return candidate;
}

DateTime startOfMonth(DateTime value) {
  return DateTime(value.year, value.month);
}

DateTime startOfNextMonth(DateTime value) {
  return DateTime(value.year, value.month + 1);
}

bool isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}
