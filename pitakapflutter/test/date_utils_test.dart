import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/core/utils/date_utils.dart';

DateTime due(DateTime anchor, BillingCycle cycle, DateTime from) {
  return nextDueDate(
    firstBillDate: anchor,
    billingCycle: cycle,
    from: from,
  );
}

void main() {
  group('startOfDay', () {
    test('strips the time component and keeps the calendar day', () {
      expect(
        startOfDay(DateTime(2026, 8, 12, 23, 59, 59, 999)),
        DateTime(2026, 8, 12),
      );
    });

    test('is idempotent', () {
      final once = startOfDay(DateTime(2026, 8, 12, 7, 30));

      expect(startOfDay(once), once);
    });
  });

  group('isSameDay', () {
    test('ignores the time on both sides', () {
      expect(
        isSameDay(DateTime(2026, 8, 15, 0, 0, 1), DateTime(2026, 8, 15, 23, 59)),
        isTrue,
      );
    });

    test('one minute past midnight is a different day', () {
      expect(
        isSameDay(DateTime(2026, 8, 15, 23, 59), DateTime(2026, 8, 16, 0, 1)),
        isFalse,
      );
    });

    test('the same day in a different month or year does not match', () {
      expect(isSameDay(DateTime(2026, 8, 15), DateTime(2026, 9, 15)), isFalse);
      expect(isSameDay(DateTime(2025, 8, 15), DateTime(2026, 8, 15)), isFalse);
    });
  });

  group('daysInMonth', () {
    test('returns the correct length for every month of a common year', () {
      const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

      for (var month = 1; month <= 12; month++) {
        expect(daysInMonth(2026, month), lengths[month - 1], reason: '$month');
      }
    });

    test('returns 29 for February in a leap year', () {
      expect(daysInMonth(2024, 2), 29);
    });

    test('honours the century leap year rules', () {
      expect(daysInMonth(2000, 2), 29);
      expect(daysInMonth(1900, 2), 28);
    });
  });

  group('daysBetween', () {
    test('counts whole calendar days regardless of time of day', () {
      expect(
        daysBetween(DateTime(2026, 8, 12, 23, 0), DateTime(2026, 8, 13, 1, 0)),
        1,
      );
    });

    test('returns zero for the same day', () {
      expect(daysBetween(DateTime(2026, 8, 12), DateTime(2026, 8, 12, 18)), 0);
    });

    test('returns a negative count when the target is in the past', () {
      expect(daysBetween(DateTime(2026, 8, 12), DateTime(2026, 8, 5)), -7);
    });

    test('spans month and year boundaries', () {
      expect(daysBetween(DateTime(2025, 12, 25), DateTime(2026, 1, 1)), 7);
    });
  });

  group('addMonths', () {
    test('adds whole months inside the same year', () {
      expect(addMonths(DateTime(2026, 1, 15), 2), DateTime(2026, 3, 15));
    });

    test('rolls over into the next year', () {
      expect(addMonths(DateTime(2026, 11, 10), 3), DateTime(2027, 2, 10));
    });

    test('clamps a 31st anchor to a shorter month', () {
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonths(DateTime(2026, 1, 31), 3), DateTime(2026, 4, 30));
    });

    test('clamps to 29 February in a leap year', () {
      expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
    });

    test('never loses the anchor day when a longer month comes back', () {
      expect(addMonths(DateTime(2026, 1, 31), 2), DateTime(2026, 3, 31));
      expect(addMonths(DateTime(2026, 1, 31), 12), DateTime(2027, 1, 31));
    });

    test('returns the anchor for zero months', () {
      expect(addMonths(DateTime(2026, 8, 12), 0), DateTime(2026, 8, 12));
    });
  });

  group('nextDueDate — before the first bill', () {
    test('returns the first bill date when it is still in the future', () {
      expect(
        due(DateTime(2030, 1, 1), BillingCycle.monthly, DateTime(2026, 8, 12)),
        DateTime(2030, 1, 1),
      );
    });

    test('returns the first bill date on the day it falls due', () {
      expect(
        due(DateTime(2026, 8, 12), BillingCycle.monthly, DateTime(2026, 8, 12)),
        DateTime(2026, 8, 12),
      );
    });

    test('ignores the time of day on the reference date', () {
      expect(
        due(
          DateTime(2026, 8, 12),
          BillingCycle.monthly,
          DateTime(2026, 8, 12, 23, 59),
        ),
        DateTime(2026, 8, 12),
      );
    });
  });

  group('nextDueDate — weekly', () {
    test('advances a week once the anchor day has passed', () {
      expect(
        due(DateTime(2026, 8, 12), BillingCycle.weekly, DateTime(2026, 8, 13)),
        DateTime(2026, 8, 19),
      );
    });

    test('lands exactly on a multiple of seven days', () {
      expect(
        due(DateTime(2026, 8, 12), BillingCycle.weekly, DateTime(2026, 8, 26)),
        DateTime(2026, 8, 26),
      );
    });

    test('crosses a month boundary', () {
      expect(
        due(DateTime(2026, 8, 31), BillingCycle.weekly, DateTime(2026, 9, 1)),
        DateTime(2026, 9, 7),
      );
    });

    test('crosses a year boundary', () {
      expect(
        due(DateTime(2026, 12, 28), BillingCycle.weekly, DateTime(2026, 12, 29)),
        DateTime(2027, 1, 4),
      );
    });

    test('skips forward correctly over a long gap', () {
      expect(
        due(DateTime(2026, 1, 1), BillingCycle.weekly, DateTime(2026, 8, 12)),
        DateTime(2026, 8, 13),
      );
    });
  });

  group('nextDueDate — monthly', () {
    test('advances to the same day next month', () {
      expect(
        due(DateTime(2026, 8, 12), BillingCycle.monthly, DateTime(2026, 8, 13)),
        DateTime(2026, 9, 12),
      );
    });

    test('clamps a 31st anchor to the end of February', () {
      expect(
        due(DateTime(2026, 1, 31), BillingCycle.monthly, DateTime(2026, 2, 1)),
        DateTime(2026, 2, 28),
      );
    });

    test('clamps a 31st anchor to 29 February in a leap year', () {
      expect(
        due(DateTime(2024, 1, 31), BillingCycle.monthly, DateTime(2024, 2, 1)),
        DateTime(2024, 2, 29),
      );
    });

    test('restores the 31st once a long month returns', () {
      expect(
        due(DateTime(2026, 1, 31), BillingCycle.monthly, DateTime(2026, 3, 1)),
        DateTime(2026, 3, 31),
      );
    });

    test('clamps a 31st anchor to a 30 day month', () {
      expect(
        due(DateTime(2026, 3, 31), BillingCycle.monthly, DateTime(2026, 4, 1)),
        DateTime(2026, 4, 30),
      );
    });

    test('does not drift after many clamped periods', () {
      expect(
        due(DateTime(2026, 1, 31), BillingCycle.monthly, DateTime(2027, 1, 1)),
        DateTime(2027, 1, 31),
      );
    });

    test('crosses a year boundary', () {
      expect(
        due(DateTime(2026, 12, 5), BillingCycle.monthly, DateTime(2026, 12, 6)),
        DateTime(2027, 1, 5),
      );
    });
  });

  group('nextDueDate — quarterly', () {
    test('advances three months at a time', () {
      expect(
        due(DateTime(2026, 1, 15), BillingCycle.quarterly, DateTime(2026, 5, 1)),
        DateTime(2026, 7, 15),
      );
    });

    test('returns the exact anniversary when the reference lands on it', () {
      expect(
        due(
          DateTime(2026, 1, 15),
          BillingCycle.quarterly,
          DateTime(2026, 4, 15),
        ),
        DateTime(2026, 4, 15),
      );
    });

    test('clamps a 31st anchor within the quarter step', () {
      expect(
        due(DateTime(2026, 1, 31), BillingCycle.quarterly, DateTime(2026, 2, 1)),
        DateTime(2026, 4, 30),
      );
    });
  });

  group('nextDueDate — yearly', () {
    test('returns this year when the anniversary is still ahead', () {
      expect(
        due(DateTime(2020, 12, 25), BillingCycle.yearly, DateTime(2026, 8, 12)),
        DateTime(2026, 12, 25),
      );
    });

    test('rolls to next year once the anniversary has passed', () {
      expect(
        due(DateTime(2020, 3, 1), BillingCycle.yearly, DateTime(2026, 8, 12)),
        DateTime(2027, 3, 1),
      );
    });

    test('clamps a 29 February anchor to 28 February in a common year', () {
      expect(
        due(DateTime(2024, 2, 29), BillingCycle.yearly, DateTime(2025, 1, 1)),
        DateTime(2025, 2, 28),
      );
    });

    test('restores 29 February on the next leap year', () {
      expect(
        due(DateTime(2024, 2, 29), BillingCycle.yearly, DateTime(2028, 1, 1)),
        DateTime(2028, 2, 29),
      );
    });
  });

  group('upcomingDueDates', () {
    test('returns the requested number of dates in ascending order', () {
      final dates = upcomingDueDates(
        firstBillDate: DateTime(2026, 8, 12),
        billingCycle: BillingCycle.monthly,
        from: DateTime(2026, 8, 12),
        count: 3,
      );

      expect(dates, [
        DateTime(2026, 8, 12),
        DateTime(2026, 9, 12),
        DateTime(2026, 10, 12),
      ]);
    });

    test('keeps the anchor day across clamped months', () {
      final dates = upcomingDueDates(
        firstBillDate: DateTime(2026, 1, 31),
        billingCycle: BillingCycle.monthly,
        from: DateTime(2026, 1, 31),
        count: 5,
      );

      expect(dates, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
        DateTime(2026, 5, 31),
      ]);
    });

    test('walks weekly cycles across a month boundary', () {
      final dates = upcomingDueDates(
        firstBillDate: DateTime(2026, 8, 26),
        billingCycle: BillingCycle.weekly,
        from: DateTime(2026, 8, 26),
        count: 3,
      );

      expect(dates, [
        DateTime(2026, 8, 26),
        DateTime(2026, 9, 2),
        DateTime(2026, 9, 9),
      ]);
    });

    test('starts from the first future bill when the anchor is ahead', () {
      final dates = upcomingDueDates(
        firstBillDate: DateTime(2027, 1, 1),
        billingCycle: BillingCycle.yearly,
        from: DateTime(2026, 8, 12),
        count: 2,
      );

      expect(dates, [DateTime(2027, 1, 1), DateTime(2028, 1, 1)]);
    });

    test('returns an empty list for a count of zero', () {
      final dates = upcomingDueDates(
        firstBillDate: DateTime(2026, 8, 12),
        billingCycle: BillingCycle.monthly,
        from: DateTime(2026, 8, 12),
        count: 0,
      );

      expect(dates, isEmpty);
    });
  });

  group('BillingCycle', () {
    test('maps every wire value back to its cycle', () {
      for (final cycle in BillingCycle.values) {
        expect(BillingCycle.fromWire(cycle.wireValue), cycle);
      }
    });

    test('falls back to monthly for unknown or missing values', () {
      expect(BillingCycle.fromWire(null), BillingCycle.monthly);
      expect(BillingCycle.fromWire(''), BillingCycle.monthly);
      expect(BillingCycle.fromWire('fortnightly'), BillingCycle.monthly);
    });

    test('exposes the number of periods in a year', () {
      expect(BillingCycle.weekly.periodsPerYear, 52);
      expect(BillingCycle.monthly.periodsPerYear, 12);
      expect(BillingCycle.quarterly.periodsPerYear, 4);
      expect(BillingCycle.yearly.periodsPerYear, 1);
    });
  });
}
