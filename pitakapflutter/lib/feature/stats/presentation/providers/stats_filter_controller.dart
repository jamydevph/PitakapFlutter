import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitakapflutter/core/utils/billing_date_utils.dart';
import 'package:pitakapflutter/feature/stats/domain/category_breakdown.dart';

class StatsFilter {
  final StatsMode mode;
  final SubscriptionView subscriptionView;
  final DateTime month;

  StatsFilter({
    this.mode = StatsMode.expenses,
    this.subscriptionView = SubscriptionView.monthly,
    required DateTime month,
  }) : month = startOfMonth(month);

  StatsFilter withMode(StatsMode value) {
    return StatsFilter(
      mode: value,
      subscriptionView: subscriptionView,
      month: month,
    );
  }

  StatsFilter withSubscriptionView(SubscriptionView value) {
    return StatsFilter(mode: mode, subscriptionView: value, month: month);
  }

  StatsFilter withMonth(DateTime value) {
    return StatsFilter(
      mode: mode,
      subscriptionView: subscriptionView,
      month: value,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StatsFilter &&
            other.mode == mode &&
            other.subscriptionView == subscriptionView &&
            other.month == month;
  }

  @override
  int get hashCode => Object.hash(mode, subscriptionView, month);
}

class StatsFilterController extends Notifier<StatsFilter> {
  @override
  StatsFilter build() => StatsFilter(month: DateTime.now());

  void selectMode(StatsMode mode) => state = state.withMode(mode);

  void selectSubscriptionView(SubscriptionView view) {
    state = state.withSubscriptionView(view);
  }

  void shiftMonth(int months) {
    state = state.withMonth(
      DateTime(state.month.year, state.month.month + months),
    );
  }

  bool canShiftForward(DateTime now) {
    return state.month.isBefore(startOfMonth(now));
  }
}

final statsFilterProvider = NotifierProvider<StatsFilterController, StatsFilter>(
  StatsFilterController.new,
);
