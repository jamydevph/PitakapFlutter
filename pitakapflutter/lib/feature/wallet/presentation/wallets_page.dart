import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/expense_providers.dart';
import 'package:pitakapflutter/core/providers/wallet_providers.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_drawer.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/restore_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/wallet_balances.dart';
import 'package:pitakapflutter/feature/wallet/presentation/widgets/wallet_tile.dart';

class WalletsPage extends ConsumerWidget {
  const WalletsPage({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    WalletEntity wallet,
  ) async {
    final confirmed = await CommonConfirmDialog.show(
      context,
      title: Strings.walletDeleteTitle,
      message: Strings.walletDeleteMessage,
      confirmLabel: Strings.walletDeleteAction,
    );

    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(deleteWalletUseCaseProvider)
          .call(DeleteWalletUseCaseParams(wallet.id));
    } catch (error) {
      if (!context.mounted) return;
      CommonSnackBar.showError(context, failureMessage(error));
      return;
    }

    if (!context.mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(Strings.walletDeleted),
          action: SnackBarAction(
            label: Strings.undoAction,
            onPressed: () => _restore(context, ref, wallet),
          ),
        ),
      );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    WalletEntity wallet,
  ) async {
    try {
      await ref
          .read(restoreWalletUseCaseProvider)
          .call(RestoreWalletUseCaseParams(wallet));
    } catch (error) {
      if (!context.mounted) return;
      CommonSnackBar.showError(context, failureMessage(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.walletsTitle)),
      drawer: const AppDrawer(),
      body: userId == null
          ? const CommonLoader.page()
          : _Body(userId: userId, onDelete: (wallet) => _delete(context, ref, wallet)),
    );
  }
}

class _Body extends ConsumerWidget {
  final String userId;
  final ValueChanged<WalletEntity> onDelete;

  const _Body({required this.userId, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsStreamProvider(userId));
    final expenses = ref.watch(allExpensesStreamProvider(userId));

    final error = wallets.error ?? expenses.error;

    if (error != null) {
      return CommonEmptyState(
        icon: Icons.cloud_off_outlined,
        title: Strings.walletsLoadFailed,
        message: failureMessage(error),
      );
    }

    if (wallets.isLoading || expenses.isLoading) {
      return const CommonLoader.page();
    }

    return _WalletsBody(
      wallets: wallets.value ?? const [],
      expenses: expenses.value ?? const [],
      onDelete: onDelete,
    );
  }
}

class _WalletsBody extends StatelessWidget {
  final List<WalletEntity> wallets;
  final List<ExpenseEntity> expenses;
  final ValueChanged<WalletEntity> onDelete;

  const _WalletsBody({
    required this.wallets,
    required this.expenses,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyCode = wallets.isEmpty ? null : wallets.first.currency;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            children: [
              _TotalBalanceCard(
                total: totalAvailable(wallets, expenses),
                currencyCode: currencyCode,
              ),
              const SizedBox(height: AppSpacing.md),
              if (wallets.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xl),
                  child: CommonEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: Strings.walletsEmptyTitle,
                    message: Strings.walletsEmptyMessage,
                  ),
                ),
              for (var index = 0; index < wallets.length; index++) ...[
                CommonListEntrance(
                  index: index,
                  child: WalletTile(
                    wallet: wallets[index],
                    available: availableBalance(wallets[index], expenses),
                    onTap: () => context.push(
                      AppRoutes.walletNew,
                      extra: wallets[index],
                    ),
                    onLongPress: () => onDelete(wallets[index]),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: CommonPrimaryButton(
              label: Strings.walletAddAction,
              onPressed: () => context.push(AppRoutes.walletNew),
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  final double total;
  final String? currencyCode;

  const _TotalBalanceCard({required this.total, this.currencyCode});

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
          Text(
            Strings.totalBalanceLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            currencyCode == null
                ? formatCurrency(total)
                : formatCurrency(total, currencyCode: currencyCode!),
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
