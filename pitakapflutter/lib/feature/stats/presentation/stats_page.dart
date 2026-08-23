import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/expense_providers.dart';
import 'package:pitakapflutter/core/providers/subscription_providers.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/core/utils/label_format.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';
import 'package:pitakapflutter/feature/stats/domain/category_breakdown.dart';
import 'package:pitakapflutter/feature/stats/presentation/providers/stats_filter_controller.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  static final DateFormat monthFormat = DateFormat('MMMM y');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value;

    if (userId == null) {
      return const Scaffold(body: CommonLoader.page());
    }

    final now = DateTime.now();
    final filter = ref.watch(statsFilterProvider);
    final controller = ref.watch(statsFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.statsTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: _ModeToggle(
                mode: filter.mode,
                onSelected: controller.selectMode,
              ),
            ),
            if (filter.mode == StatsMode.expenses)
              _MonthStepper(
                month: filter.month,
                canGoForward: controller.canShiftForward(now),
                onShift: controller.shiftMonth,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _SubscriptionViewToggle(
                  view: filter.subscriptionView,
                  onSelected: controller.selectSubscriptionView,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: filter.mode == StatsMode.expenses
                  ? _ExpensesBreakdown(userId: userId, filter: filter)
                  : _SubscriptionsBreakdown(userId: userId, filter: filter),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesBreakdown extends ConsumerWidget {
  final String userId;
  final StatsFilter filter;

  const _ExpensesBreakdown({required this.userId, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(
          expensesForMonthStreamProvider(
            WatchExpensesForMonthParams(userId: userId, month: filter.month),
          ),
        )
        .when(
          loading: () => const CommonLoader.page(),
          error: (error, _) => CommonEmptyState(
            icon: Icons.cloud_off_outlined,
            title: Strings.statsLoadFailed,
            message: failureMessage(error),
          ),
          data: (expenses) => _BreakdownView(
            breakdown: expenseBreakdown(expenses),
            caption: Strings.statsThisMonthCaption,
            emptyTitle: Strings.statsEmptyExpensesTitle,
            emptyMessage: Strings.statsEmptyExpensesMessage,
          ),
        );
  }
}

class _SubscriptionsBreakdown extends ConsumerWidget {
  final String userId;
  final StatsFilter filter;

  const _SubscriptionsBreakdown({required this.userId, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(subscriptionsStreamProvider(userId))
        .when(
          loading: () => const CommonLoader.page(),
          error: (error, _) => CommonEmptyState(
            icon: Icons.cloud_off_outlined,
            title: Strings.statsLoadFailed,
            message: failureMessage(error),
          ),
          data: (subscriptions) => _BreakdownView(
            breakdown: subscriptionBreakdown(
              subscriptions,
              view: filter.subscriptionView,
            ),
            caption: filter.subscriptionView == SubscriptionView.yearly
                ? Strings.statsPerYearCaption
                : Strings.statsPerMonthCaption,
            emptyTitle: Strings.statsEmptySubscriptionsTitle,
            emptyMessage: Strings.statsEmptySubscriptionsMessage,
          ),
        );
  }
}

class _BreakdownView extends StatelessWidget {
  final CategoryBreakdown breakdown;
  final String caption;
  final String emptyTitle;
  final String emptyMessage;

  const _BreakdownView({
    required this.breakdown,
    required this.caption,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return CommonEmptyState(
        icon: Icons.donut_large_outlined,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl * 2,
      ),
      children: [
        _Donut(breakdown: breakdown, caption: caption),
        const SizedBox(height: AppSpacing.lg),
        for (final slice in breakdown.slices) _LegendRow(slice: slice),
      ],
    );
  }
}

class _Donut extends StatelessWidget {
  final CategoryBreakdown breakdown;
  final String caption;

  const _Donut({required this.breakdown, required this.caption});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 62,
              startDegreeOffset: -90,
              sections: [
                for (final slice in breakdown.slices)
                  PieChartSectionData(
                    value: slice.amount,
                    color: AppColors.categoryAccent(slice.category),
                    radius: 28,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCurrency(breakdown.total, decimalDigits: 0),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(caption, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final CategorySlice slice;

  const _LegendRow({required this.slice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.categoryAccent(slice.category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              categoryLabel(slice.category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            formatCurrency(slice.amount, decimalDigits: 0),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 40,
            child: Text(
              '${slice.percent}%',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final StatsMode mode;
  final ValueChanged<StatsMode> onSelected;

  const _ModeToggle({required this.mode, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StatsMode>(
      segments: [
        for (final value in StatsMode.values)
          ButtonSegment(value: value, label: Text(value.label)),
      ],
      selected: {mode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}

class _SubscriptionViewToggle extends StatelessWidget {
  final SubscriptionView view;
  final ValueChanged<SubscriptionView> onSelected;

  const _SubscriptionViewToggle({
    required this.view,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SubscriptionView>(
      segments: [
        for (final value in SubscriptionView.values)
          ButtonSegment(value: value, label: Text(value.label)),
      ],
      selected: {view},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}

class _MonthStepper extends StatelessWidget {
  final DateTime month;
  final bool canGoForward;
  final ValueChanged<int> onShift;

  const _MonthStepper({
    required this.month,
    required this.canGoForward,
    required this.onShift,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onShift(-1),
            icon: const Icon(Icons.chevron_left),
            tooltip: Strings.statsPreviousMonth,
          ),
          Expanded(
            child: Text(
              StatsPage.monthFormat.format(month),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
          IconButton(
            onPressed: canGoForward ? () => onShift(1) : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: Strings.statsNextMonth,
          ),
        ],
      ),
    );
  }
}
