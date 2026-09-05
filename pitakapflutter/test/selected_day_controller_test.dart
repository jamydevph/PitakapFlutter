import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/utils/date_utils.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/presentation/providers/selected_day_controller.dart';

import 'helpers.dart';

void main() {
  test('starts on today, normalised to midnight', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);

    final day = container.read(selectedDayProvider);

    expect(day, startOfDay(DateTime.now()));
    expect(day.hour, 0);
    expect(day.isUtc, isFalse);
  });

  test('selecting a day strips its time component', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);

    container
        .read(selectedDayProvider.notifier)
        .select(DateTime(2026, 8, 15, 23, 59, 59));

    expect(container.read(selectedDayProvider), DateTime(2026, 8, 15));
  });

  test('shifting days crosses a month boundary correctly', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);

    final controller = container.read(selectedDayProvider.notifier)
      ..select(DateTime(2026, 8, 31));

    controller.shiftDays(1);
    expect(container.read(selectedDayProvider), DateTime(2026, 9, 1));

    controller.shiftDays(-1);
    expect(container.read(selectedDayProvider), DateTime(2026, 8, 31));
  });

  test('shifting back from March 1 lands on a leap day', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);

    container.read(selectedDayProvider.notifier)
      ..select(DateTime(2028, 3, 1))
      ..shiftDays(-1);

    expect(container.read(selectedDayProvider), DateTime(2028, 2, 29));
  });

  test('today() returns to the current day from anywhere', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);

    container.read(selectedDayProvider.notifier)
      ..select(DateTime(2020, 1, 1))
      ..today();

    expect(container.read(selectedDayProvider), startOfDay(DateTime.now()));
  });

  test('the selected day is a usable stream key at any time of day', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);

    container
        .read(selectedDayProvider.notifier)
        .select(DateTime(2026, 8, 15, 9, 15));
    final morning = container.read(selectedDayProvider);

    container
        .read(selectedDayProvider.notifier)
        .select(DateTime(2026, 8, 15, 21, 45));
    final evening = container.read(selectedDayProvider);

    expect(
      WatchExpensesForDayParams(userId: 'uid-1', day: morning),
      WatchExpensesForDayParams(userId: 'uid-1', day: evening),
    );
  });
}
