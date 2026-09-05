import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitakapflutter/core/utils/date_utils.dart';

class SelectedDayController extends Notifier<DateTime> {
  @override
  DateTime build() => startOfDay(DateTime.now());

  void select(DateTime day) => state = startOfDay(day);

  void today() => select(DateTime.now());

  void shiftDays(int days) {
    state = DateTime(state.year, state.month, state.day + days);
  }
}

final selectedDayProvider = NotifierProvider<SelectedDayController, DateTime>(
  SelectedDayController.new,
);
