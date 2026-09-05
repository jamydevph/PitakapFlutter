import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/date_utils.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/expense_totals.dart';

class ExpenseDayTotalCard extends StatelessWidget {
  final DateTime day;
  final DateTime today;
  final List<ExpenseEntity> expenses;

  const ExpenseDayTotalCard({
    super.key,
    required this.day,
    required this.today,
    required this.expenses,
  });

  static String dayLabel(DateTime day, DateTime today) {
    final date = DateFormat('MMM d').format(day);

    if (isSameDay(day, today)) return '${Strings.dayToday} · $date';

    final yesterday = DateTime(today.year, today.month, today.day - 1);
    if (isSameDay(day, yesterday)) return '${Strings.dayYesterday} · $date';

    return DateFormat('EEE, MMM d').format(day);
  }

  static String entriesLabel(int count) {
    return count == 1
        ? '1 ${Strings.entrySingular}'
        : '$count ${Strings.entryPlural}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currency = expenses.isEmpty
        ? Constants.defaultCurrency
        : expenses.first.currency;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayLabel(day, today),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatCurrency(
                      dailyTotal(expenses),
                      currencyCode: currency,
                    ),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                entriesLabel(expenses.length),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
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
