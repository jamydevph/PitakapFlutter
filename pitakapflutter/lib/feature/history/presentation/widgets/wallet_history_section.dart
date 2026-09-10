import 'package:flutter/material.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/core/utils/label_format.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/history/presentation/history_page.dart';
import 'package:pitakapflutter/feature/wallet/domain/wallet_history.dart';

/// A wallet header that expands to reveal that wallet's expenses.
///
/// Mint = the wallet grouping, white = an individual expense. That contrast is
/// what stops this page from reading like the Expenses list.
class WalletHistorySection extends StatelessWidget {
  final WalletHistoryGroup group;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<ExpenseEntity> onOpenExpense;

  const WalletHistorySection({
    super.key,
    required this.group,
    required this.isExpanded,
    required this.onToggle,
    required this.onOpenExpense,
  });

  static String countLabel(int count) {
    final suffix = count == 1
        ? Strings.historyExpenseSuffix
        : Strings.historyExpensesSuffix;

    return '$count $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          group: group,
          isExpanded: isExpanded,
          onToggle: onToggle,
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final expense in group.expenses) ...[
            _ExpenseRow(
              expense: expense,
              currencyCode: group.currency,
              onTap: () => onOpenExpense(expense),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final WalletHistoryGroup group;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _Header({
    required this.group,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          size: 20,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isExpanded
                          ? WalletHistorySection.countLabel(group.count)
                          : '${WalletHistorySection.countLabel(group.count)}'
                                ' · ${Strings.historyTapToExpand}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '-${formatCurrency(group.total, currencyCode: group.currency, decimalDigits: 0)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final ExpenseEntity expense;
  final String currencyCode;
  final VoidCallback onTap;

  const _ExpenseRow({
    required this.expense,
    required this.currencyCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.categoryAccent(expense.category);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                ),
                child: Text(
                  expense.description.isEmpty
                      ? '?'
                      : expense.description.characters.first.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: accent,
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
                      expense.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${categoryLabel(expense.category)}'
                      ' · ${HistoryPage.formatCompletedDate(expense.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '-${formatCurrency(expense.amount, currencyCode: currencyCode, decimalDigits: 0)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
