import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/expense_providers.dart';
import 'package:pitakapflutter/core/providers/settings_providers.dart';
import 'package:pitakapflutter/core/providers/wallet_providers.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_drawer.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/history/presentation/widgets/wallet_history_section.dart';
import 'package:pitakapflutter/feature/wallet/domain/wallet_history.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  static String formatCompletedDate(DateTime date) =>
      DateFormat('MMM d, y').format(date);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.historyTitle)),
      drawer: const AppDrawer(),
      body: userId == null
          ? const CommonLoader.page()
          : _Body(userId: userId),
    );
  }
}

class _Body extends ConsumerWidget {
  final String userId;

  const _Body({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsStreamProvider(userId));
    final expenses = ref.watch(allExpensesStreamProvider(userId));

    final error = wallets.error ?? expenses.error;

    if (error != null) {
      return CommonEmptyState(
        icon: Icons.cloud_off_outlined,
        title: Strings.historyLoadFailed,
        message: failureMessage(error),
      );
    }

    if (wallets.isLoading || expenses.isLoading) {
      return const CommonLoader.page();
    }

    final groups = walletHistoryGroups(
      wallets: wallets.value ?? const [],
      expenses: expenses.value ?? const [],
      unassignedName: Strings.historyUnassignedTitle,
      unassignedDescription: Strings.historyUnassignedDescription,
      fallbackCurrency: ref.watch(defaultCurrencyProvider),
    );

    if (groups.isEmpty) {
      return const CommonEmptyState(
        icon: Icons.history_outlined,
        title: Strings.historyEmptyTitle,
        message: Strings.historyEmptyMessage,
      );
    }

    return _HistoryList(groups: groups);
  }
}

class _HistoryList extends StatefulWidget {
  final List<WalletHistoryGroup> groups;

  const _HistoryList({required this.groups});

  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList> {
  /// The first wallet starts open so the page never reads as an empty
  /// stack of collapsed bars; everything else is opened on demand.
  final Set<String> _expanded = {};
  bool _touched = false;

  Set<String> get _openIds {
    if (_touched || widget.groups.isEmpty) return _expanded;

    return {widget.groups.first.walletId};
  }

  void _toggle(String walletId) {
    setState(() {
      if (!_touched) {
        _touched = true;
        _expanded
          ..clear()
          ..addAll({widget.groups.first.walletId});
      }

      if (!_expanded.remove(walletId)) _expanded.add(walletId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final open = _openIds;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl * 2,
      ),
      itemCount: widget.groups.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final group = widget.groups[index];

        return CommonListEntrance(
          index: index,
          child: WalletHistorySection(
            group: group,
            isExpanded: open.contains(group.walletId),
            onToggle: () => _toggle(group.walletId),
            onOpenExpense: (ExpenseEntity expense) =>
                context.push(AppRoutes.expenseNew, extra: expense),
          ),
        );
      },
    );
  }
}
