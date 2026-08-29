import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/expense_providers.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/billing_date_utils.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/restore_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/presentation/providers/selected_day_controller.dart';
import 'package:pitakapflutter/feature/expense/presentation/widgets/expense_date_strip.dart';
import 'package:pitakapflutter/feature/expense/presentation/widgets/expense_day_total_card.dart';
import 'package:pitakapflutter/feature/expense/presentation/widgets/expense_tile.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  static const int historyYears = 5;

  Future<void> _pickDay(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDay,
    DateTime today,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDay,
      firstDate: DateTime(today.year - historyYears),
      lastDate: today,
      helpText: Strings.expensesPickDate,
    );

    if (picked == null) return;

    ref.read(selectedDayProvider.notifier).select(picked);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ExpenseEntity expense,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(deleteExpenseUseCaseProvider)
          .call(DeleteExpenseUseCaseParams(expense.id));
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
          content: const Text(Strings.expenseDeleted),
          action: SnackBarAction(
            label: Strings.undoAction,
            onPressed: () => _restore(context, ref, expense),
          ),
        ),
      );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    ExpenseEntity expense,
  ) async {
    try {
      await ref
          .read(restoreExpenseUseCaseProvider)
          .call(RestoreExpenseUseCaseParams(expense));
    } catch (error) {
      if (!context.mounted) return;
      CommonSnackBar.showError(context, failureMessage(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value;
    final selectedDay = ref.watch(selectedDayProvider);
    final today = startOfDay(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.expensesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: Strings.expensesPickDate,
            onPressed: () => _pickDay(context, ref, selectedDay, today),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.expenseNew),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          ExpenseDateStrip(
            selectedDay: selectedDay,
            today: today,
            onSelected: ref.read(selectedDayProvider.notifier).select,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: userId == null
                ? const CommonLoader.page()
                : ref
                      .watch(
                        expensesForDayStreamProvider(
                          WatchExpensesForDayParams(
                            userId: userId,
                            day: selectedDay,
                          ),
                        ),
                      )
                      .when(
                        loading: () => const CommonLoader.page(),
                        error: (error, _) => CommonEmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: Strings.expensesLoadFailed,
                          message: failureMessage(error),
                        ),
                        data: (expenses) => _DayBody(
                          day: selectedDay,
                          today: today,
                          expenses: expenses,
                          onDelete: (expense) => _delete(context, ref, expense),
                          onOpen: (expense) => context.push(
                            AppRoutes.expenseNew,
                            extra: expense,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _DayBody extends StatelessWidget {
  final DateTime day;
  final DateTime today;
  final List<ExpenseEntity> expenses;
  final ValueChanged<ExpenseEntity> onDelete;
  final ValueChanged<ExpenseEntity> onOpen;

  const _DayBody({
    required this.day,
    required this.today,
    required this.expenses,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = isSameDay(day, today);

    return Column(
      children: [
        ExpenseDayTotalCard(day: day, today: today, expenses: expenses),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: expenses.isEmpty
              ? CommonEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: isToday
                      ? Strings.expensesEmptyTodayTitle
                      : Strings.expensesEmptyPastTitle,
                  message: isToday
                      ? Strings.expensesEmptyTodayMessage
                      : Strings.expensesEmptyPastMessage,
                )
              : _ExpenseList(
                  expenses: expenses,
                  onDelete: onDelete,
                  onOpen: onOpen,
                ),
        ),
      ],
    );
  }
}

class _ExpenseList extends StatelessWidget {
  final List<ExpenseEntity> expenses;
  final ValueChanged<ExpenseEntity> onDelete;
  final ValueChanged<ExpenseEntity> onOpen;

  const _ExpenseList({
    required this.expenses,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xl * 2,
      ),
      itemCount: expenses.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final expense = expenses[index];

        return Dismissible(
          key: ValueKey(expense.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDelete(expense),
          background: const _DeleteBackground(),
          child: ExpenseTile(
            expense: expense,
            onTap: () => onOpen(expense),
          ),
        );
      },
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Icon(Icons.delete_outline, color: colorScheme.onError),
    );
  }
}
