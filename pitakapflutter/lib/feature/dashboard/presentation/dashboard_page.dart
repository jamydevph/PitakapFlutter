import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/dashboard_providers.dart';
import 'package:pitakapflutter/core/providers/expense_providers.dart';
import 'package:pitakapflutter/core/providers/subscription_providers.dart';
import 'package:pitakapflutter/core/providers/wallet_providers.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_drawer.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/date_utils.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/feature/dashboard/domain/entities/spending_summary.dart';
import 'package:pitakapflutter/feature/dashboard/domain/usecases/get_spending_summary_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/subscription/presentation/widgets/subscription_tile.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/wallet_balances.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static const int wordsWithinDays = 6;

  static String greetingFor(DateTime now) {
    if (now.hour < 12) return Strings.greetingMorning;
    if (now.hour < 18) return Strings.greetingAfternoon;

    return Strings.greetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value;

    if (userId == null) {
      return const Scaffold(
        appBar: _DashboardAppBar(),
        drawer: AppDrawer(),
        body: CommonLoader.page(),
      );
    }

    final now = DateTime.now();
    final today = startOfDay(now);

    final subscriptions = ref.watch(subscriptionsStreamProvider(userId));
    final expenses = ref.watch(
      expensesForDayStreamProvider(
        WatchExpensesForDayParams(userId: userId, day: today),
      ),
    );
    final details = ref.watch(userDetailsProvider(userId));

    final error = subscriptions.error ?? expenses.error;

    if (error != null) {
      return Scaffold(
        appBar: const _DashboardAppBar(),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: CommonEmptyState(
            icon: Icons.cloud_off_outlined,
            title: Strings.dashboardLoadFailed,
            message: failureMessage(error),
          ),
        ),
      );
    }

    if (subscriptions.isLoading || expenses.isLoading) {
      return const Scaffold(
        appBar: _DashboardAppBar(),
        drawer: AppDrawer(),
        body: CommonLoader.page(),
      );
    }

    final summary = ref
        .watch(getSpendingSummaryUseCaseProvider)
        .call(
          GetSpendingSummaryUseCaseParams(
            subscriptions: subscriptions.value ?? const [],
            expensesToday: expenses.value ?? const [],
            now: now,
          ),
        );

    return Scaffold(
      appBar: const _DashboardAppBar(),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl * 2,
          ),
          children: [
            _Greeting(now: now, firstName: details.value?.firstName ?? ''),
            const SizedBox(height: AppSpacing.md),
            _SpentTodayCard(summary: summary, now: now),
            const SizedBox(height: AppSpacing.md),
            _TotalBalanceCard(userId: userId),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: Strings.subsPerMonthLabel,
                    value: formatCurrency(
                      summary.monthlySubscriptionCost,
                      decimalDigits: 0,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    label: Strings.subsPerYearLabel,
                    value: formatCurrency(
                      summary.yearlySubscriptionCost,
                      decimalDigits: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _UpcomingSection(summary: summary),
          ],
        ),
      ),
    );
  }
}

/// The dashboard leads with a greeting rather than a title, so its app bar
/// exists only to host the drawer button.
class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(toolbarHeight: kToolbarHeight);
}

class _Greeting extends StatelessWidget {
  final DateTime now;
  final String firstName;

  const _Greeting({required this.now, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DashboardPage.greetingFor(now), style: theme.textTheme.bodyMedium),
        if (firstName.isNotEmpty)
          Text(firstName, style: theme.textTheme.headlineSmall),
      ],
    );
  }
}

class _SpentTodayCard extends StatelessWidget {
  final SpendingSummary summary;
  final DateTime now;

  const _SpentTodayCard({required this.summary, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Strings.spentTodayLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                DateFormat('EEE, MMM d').format(now),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatCurrency(summary.spentToday),
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${summary.activeSubscriptionCount} ${Strings.activeSuffix}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mint against the primary-green "spent today" card above it: money you have
/// versus money you spent. Wallets failing to load must not take the dashboard
/// down with them, so this collapses to nothing instead of erroring.
class _TotalBalanceCard extends ConsumerWidget {
  final String userId;

  const _TotalBalanceCard({required this.userId});

  static String walletCountLabel(int count) {
    final suffix = count == 1
        ? Strings.walletCountSuffix
        : Strings.walletsCountSuffix;

    return '$count $suffix';
  }

  static String breakdownOf(
    List<WalletEntity> wallets,
    Map<String, double> balances,
  ) {
    return wallets
        .map(
          (wallet) =>
              '${wallet.name} '
              '${formatCurrency(balances[wallet.id] ?? 0, currencyCode: wallet.currency, decimalDigits: 0)}',
        )
        .join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final wallets = ref.watch(walletsStreamProvider(userId)).value;
    final expenses = ref.watch(allExpensesStreamProvider(userId)).value;

    if (wallets == null || expenses == null || wallets.isEmpty) {
      return const SizedBox.shrink();
    }

    final balances = balancesByWallet(wallets, expenses);
    final total = totalAvailable(wallets, expenses);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      Strings.totalBalanceLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Text(
                  walletCountLabel(wallets.length),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              formatCurrency(total, currencyCode: wallets.first.currency),
              style: theme.textTheme.displaySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              breakdownOf(wallets, balances),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  final SpendingSummary summary;

  const _UpcomingSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (summary.upcomingPayments.isEmpty) {
      return const CommonEmptyState(
        icon: Icons.insights_outlined,
        title: Strings.dashboardEmptyTitle,
        message: Strings.dashboardEmptyMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Strings.upcomingPaymentsLabel,
              style: theme.textTheme.titleSmall,
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.subscriptions),
              child: const Text(Strings.seeAllAction),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final payment in summary.upcomingPayments) ...[
          _UpcomingTile(payment: payment),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final UpcomingPayment payment;

  const _UpcomingTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final subscription = payment.subscription;
    final accent = AppColors.categoryAccent(subscription.category);
    final isSoon = payment.daysUntil <= SubscriptionTile.soonThresholdDays;
    final isThisWeek = payment.daysUntil <= DashboardPage.wordsWithinDays;

    final background = isSoon
        ? colorScheme.error.withValues(alpha: 0.14)
        : isThisWeek
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;

    final foreground = isSoon
        ? colorScheme.error
        : isThisWeek
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: accent,
              child: Text(
                subscription.name.isEmpty
                    ? '?'
                    : subscription.name.characters.first.toUpperCase(),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatCurrency(subscription.amount, currencyCode: subscription.currency, decimalDigits: 0)}'
                    ' · ${subscription.billingCycle.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                SubscriptionTile.dueLabel(
                  payment.daysUntil,
                  payment.dueDate,
                  wordsWithinDays: DashboardPage.wordsWithinDays,
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
