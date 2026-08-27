import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/reminder_schedule.dart';

SubscriptionEntity sub({
  String id = 'sub-1',
  String name = 'Netflix',
  DateTime? firstBillDate,
  BillingCycle cycle = BillingCycle.monthly,
  int reminderDaysBefore = 3,
  bool isActive = true,
}) {
  return SubscriptionEntity(
    id: id,
    userId: 'uid-1',
    name: name,
    category: 'entertainment',
    amount: 549,
    billingCycle: cycle,
    firstBillDate: firstBillDate ?? DateTime(2024, 1, 15),
    reminderDaysBefore: reminderDaysBefore,
    isActive: isActive,
  );
}

void main() {
  group('reminderIdFor', () {
    test('is deterministic for the same document id', () {
      expect(reminderIdFor('abc123'), reminderIdFor('abc123'));
    });

    test('differs for different document ids', () {
      expect(reminderIdFor('abc123'), isNot(reminderIdFor('abc124')));
    });

    test('⭐ always fits a positive 31-bit int', () {
      final ids = [
        '',
        'a',
        'YmZ1kQx8p2LmNoPqRsTu',
        'a-very-long-firestore-document-id-that-keeps-going-and-going',
        '////////////////////',
      ];

      for (final id in ids) {
        final value = reminderIdFor(id);
        expect(value, greaterThanOrEqualTo(0), reason: id);
        expect(value, lessThanOrEqualTo(reminderIdMask), reason: id);
      }
    });

    test('an empty id is still a valid notification id', () {
      expect(reminderIdFor(''), 0);
    });
  });

  group('reminderTimeFor', () {
    test('lands the requested number of days before, at the reminder hour', () {
      final fireAt = reminderTimeFor(
        dueDate: DateTime(2026, 8, 20),
        daysBefore: 3,
      );

      expect(fireAt, DateTime(2026, 8, 17, reminderHourOfDay));
    });

    test('zero days before fires on the due date itself', () {
      final fireAt = reminderTimeFor(
        dueDate: DateTime(2026, 8, 20),
        daysBefore: 0,
      );

      expect(fireAt, DateTime(2026, 8, 20, reminderHourOfDay));
    });

    test('⭐ crosses a month boundary backwards', () {
      final fireAt = reminderTimeFor(
        dueDate: DateTime(2026, 9, 2),
        daysBefore: 5,
      );

      expect(fireAt, DateTime(2026, 8, 28, reminderHourOfDay));
    });

    test('⭐ crosses a leap day backwards', () {
      final fireAt = reminderTimeFor(
        dueDate: DateTime(2028, 3, 1),
        daysBefore: 2,
      );

      expect(fireAt, DateTime(2028, 2, 28, reminderHourOfDay));
    });

    test('ignores any time component on the due date', () {
      final fireAt = reminderTimeFor(
        dueDate: DateTime(2026, 8, 20, 23, 59, 59),
        daysBefore: 1,
      );

      expect(fireAt, DateTime(2026, 8, 19, reminderHourOfDay));
    });

    test('the result is local, never UTC', () {
      final fireAt = reminderTimeFor(
        dueDate: DateTime(2026, 8, 20),
        daysBefore: 3,
      );

      expect(fireAt.isUtc, isFalse);
    });
  });

  group('reminderFor', () {
    test('schedules ahead of the next due date', () {
      final reminder = reminderFor(
        sub(firstBillDate: DateTime(2024, 1, 20), reminderDaysBefore: 3),
        now: DateTime(2026, 8, 1, 10),
      );

      expect(reminder, isNotNull);
      expect(reminder!.dueDate, DateTime(2026, 8, 20));
      expect(reminder.fireAt, DateTime(2026, 8, 17, reminderHourOfDay));
      expect(reminder.subscriptionId, 'sub-1');
      expect(reminder.id, reminderIdFor('sub-1'));
    });

    test('⭐ an inactive subscription gets no reminder', () {
      final reminder = reminderFor(
        sub(isActive: false),
        now: DateTime(2026, 8, 1),
      );

      expect(reminder, isNull);
    });

    test('⭐ skips to the following cycle when this one already passed', () {
      final reminder = reminderFor(
        sub(firstBillDate: DateTime(2024, 1, 20), reminderDaysBefore: 3),
        now: DateTime(2026, 8, 18, 10),
      );

      expect(reminder, isNotNull);
      expect(reminder!.dueDate, DateTime(2026, 9, 20));
      expect(reminder.fireAt, DateTime(2026, 9, 17, reminderHourOfDay));
    });

    test('⭐ the boundary is strict — a fire time of exactly now is skipped', () {
      final now = DateTime(2026, 8, 17, reminderHourOfDay);

      final reminder = reminderFor(
        sub(firstBillDate: DateTime(2024, 1, 20), reminderDaysBefore: 3),
        now: now,
      );

      expect(reminder, isNotNull);
      expect(reminder!.fireAt.isAfter(now), isTrue);
      expect(reminder.dueDate, DateTime(2026, 9, 20));
    });

    test('a same-day reminder still schedules when the hour is ahead', () {
      final reminder = reminderFor(
        sub(firstBillDate: DateTime(2024, 1, 20), reminderDaysBefore: 0),
        now: DateTime(2026, 8, 20, 6),
      );

      expect(reminder, isNotNull);
      expect(reminder!.fireAt, DateTime(2026, 8, 20, reminderHourOfDay));
      expect(reminder.dueDate, DateTime(2026, 8, 20));
    });

    test('⭐ every cycle produces a future fire time', () {
      final now = DateTime(2026, 8, 18, 14);

      for (final cycle in BillingCycle.values) {
        final reminder = reminderFor(
          sub(
            firstBillDate: DateTime(2024, 1, 20),
            cycle: cycle,
            reminderDaysBefore: 3,
          ),
          now: now,
        );

        expect(reminder, isNotNull, reason: cycle.label);
        expect(reminder!.fireAt.isAfter(now), isTrue, reason: cycle.label);
      }
    });

    test('ScheduledReminder has value equality', () {
      final a = reminderFor(sub(), now: DateTime(2026, 8, 1));
      final b = reminderFor(sub(), now: DateTime(2026, 8, 1));

      expect(a, b);
    });
  });
}
