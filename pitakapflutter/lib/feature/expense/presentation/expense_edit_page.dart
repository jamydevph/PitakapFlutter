import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/expense_providers.dart';
import 'package:pitakapflutter/core/providers/settings_providers.dart';
import 'package:pitakapflutter/core/providers/wallet_providers.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/amount_input_formatter.dart';
import 'package:pitakapflutter/core/utils/date_utils.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/core/utils/label_format.dart';
import 'package:pitakapflutter/core/utils/validators.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/presentation/providers/expense_edit_controller.dart';
import 'package:pitakapflutter/feature/expense/presentation/providers/expense_edit_state.dart';
import 'package:pitakapflutter/feature/expense/presentation/providers/selected_day_controller.dart';
import 'package:pitakapflutter/feature/expense/presentation/widgets/expense_day_total_card.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/wallet_balances.dart';

class ExpenseEditPage extends ConsumerStatefulWidget {
  final ExpenseEntity? expense;

  const ExpenseEditPage({super.key, this.expense});

  static const int historyYears = 5;

  @override
  ConsumerState<ExpenseEditPage> createState() => _ExpenseEditPageState();
}

class _ExpenseEditPageState extends ConsumerState<ExpenseEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late String _category;
  late String _paymentMethod;
  late String _walletId;
  late DateTime _date;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.expense;

    _amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _category = existing?.category ?? Constants.expenseCategories.first;
    _paymentMethod = existing?.paymentMethod ?? '';
    _walletId = existing?.walletId ?? '';
    _date = existing?.date ?? ref.read(selectedDayProvider);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = startOfDay(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(today.year - ExpenseEditPage.historyYears),
      lastDate: today,
      helpText: Strings.expensesPickDate,
    );

    if (picked != null) setState(() => _date = startOfDay(picked));
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppRoutes.expenses);
  }

  /// A wallet may not be overdrawn. The wallet being edited is excluded from
  /// its own balance so raising an amount is judged against the new figure,
  /// not the old one counted twice.
  ///
  /// Both lists are watched in [build] rather than read here: a `ref.read` on
  /// a provider nothing is listening to comes back still loading, which would
  /// silently wave every overdraft through.
  bool _fits(
    List<WalletEntity> wallets,
    List<ExpenseEntity> expenses,
    double amount,
  ) {
    if (_walletId.isEmpty) return true;

    final wallet = wallets.where((item) => item.id == _walletId).firstOrNull;
    if (wallet == null) return true;

    return canAfford(
      wallet: wallet,
      expenses: expenses,
      editingExpenseId: widget.expense?.id ?? '',
      newAmount: amount,
    );
  }

  void _save(
    String userId,
    List<WalletEntity> wallets,
    List<ExpenseEntity> expenses,
  ) {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) return;

    final amount = double.parse(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    final controller = ref.read(expenseEditControllerProvider.notifier);
    final existing = widget.expense;

    if (!_fits(wallets, expenses, amount)) {
      CommonSnackBar.showError(context, Strings.expenseWalletInsufficient);
      return;
    }

    if (existing == null) {
      controller.create(
        CreateExpenseUseCaseParams(
          userId: userId,
          description: description,
          category: _category,
          amount: amount,
          date: _date,
          currency: ref.read(defaultCurrencyProvider),
          paymentMethod: _paymentMethod,
          walletId: _walletId,
        ),
      );
      return;
    }

    controller.updateExisting(
      ExpenseEntity(
        id: existing.id,
        userId: existing.userId,
        description: description,
        category: _category,
        amount: amount,
        currency: existing.currency,
        paymentMethod: _paymentMethod,
        walletId: _walletId,
        date: _date,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editState = ref.watch(expenseEditControllerProvider).value;
    final isBusy = editState is ExpenseEditLoadingState;
    final userId = ref.watch(authStateProvider).value;
    final String currencyCode =
        widget.expense?.currency ?? ref.watch(defaultCurrencyProvider);
    final today = startOfDay(DateTime.now());
    final wallets = userId == null
        ? const <WalletEntity>[]
        : ref.watch(walletsStreamProvider(userId)).value ??
              const <WalletEntity>[];
    final walletExpenses = userId == null
        ? const <ExpenseEntity>[]
        : ref.watch(allExpensesStreamProvider(userId)).value ??
              const <ExpenseEntity>[];

    ref.listen(expenseEditControllerProvider, (previous, next) {
      final state = next.value;

      if (state is ExpenseEditFailedState) {
        CommonSnackBar.showError(context, state.message);
        ref.read(expenseEditControllerProvider.notifier).reset();
        return;
      }

      if (state is ExpenseEditSuccessState) {
        CommonSnackBar.showSuccess(
          context,
          state.wasExisting ? Strings.expenseUpdated : Strings.expenseCreated,
        );
        ref.read(expenseEditControllerProvider.notifier).reset();
        _close();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing
                          ? Strings.expenseEditTitle
                          : Strings.expenseAddTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: isBusy ? null : _close,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  children: [
                    _AmountCard(
                      controller: _amountController,
                      enabled: !isBusy,
                      currencyCode: currencyCode,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionLabel(Strings.expenseCategoryLabel),
                    _ChoiceChips<String>(
                      values: Constants.expenseCategories,
                      selected: _category,
                      labelOf: categoryLabel,
                      enabled: !isBusy,
                      onSelected: (value) => setState(() => _category = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CommonTextField(
                      controller: _descriptionController,
                      label: Strings.expenseDescriptionLabel,
                      hint: Strings.expenseDescriptionHint,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      enabled: !isBusy,
                      validator: (value) => Validators.notEmpty(
                        value,
                        Strings.expenseDescriptionRequired,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _PickerField(
                      label: Strings.expenseDateLabel,
                      value: ExpenseDayTotalCard.dayLabel(_date, today),
                      icon: Icons.calendar_today_outlined,
                      onTap: isBusy ? null : _pickDate,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionLabel(Strings.expensePaymentMethodLabel),
                    _ChoiceChips<String>(
                      values: Constants.paymentMethods,
                      selected: _paymentMethod,
                      labelOf: paymentMethodLabel,
                      enabled: !isBusy,
                      onSelected: (value) => setState(
                        () => _paymentMethod = _paymentMethod == value
                            ? ''
                            : value,
                      ),
                    ),
                    if (wallets.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _SectionLabel(Strings.expenseWalletLabel),
                      _ChoiceChips<String>(
                        values: [
                          '',
                          for (final wallet in wallets) wallet.id,
                        ],
                        selected: _walletId,
                        labelOf: (id) => _walletNameFor(wallets, id),
                        enabled: !isBusy,
                        onSelected: (value) =>
                            setState(() => _walletId = value),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CommonPrimaryButton(
                label: Strings.expenseSaveAction,
                onPressed: userId == null
                    ? null
                    : () => _save(userId, wallets, walletExpenses),
                isLoading: isBusy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _walletNameFor(List<WalletEntity> wallets, String id) {
  if (id.isEmpty) return Strings.expenseWalletNone;

  return wallets.where((wallet) => wallet.id == id).firstOrNull?.name ?? id;
}

class _AmountCard extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String currencyCode;

  const _AmountCard({
    required this.controller,
    required this.enabled,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Text(Strings.expenseAmountLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                currencySymbol(currencyCode),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IntrinsicWidth(
                child: TextFormField(
                  controller: controller,
                  enabled: enabled,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [AmountInputFormatter()],
                  style: theme.textTheme.displaySmall,
                  decoration: const InputDecoration(
                    hintText: '0',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  validator: Validators.amount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _ChoiceChips<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final bool enabled;

  const _ChoiceChips({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: values.map((value) {
        return ChoiceChip(
          label: Text(labelOf(value)),
          selected: value == selected,
          onSelected: enabled ? (_) => onSelected(value) : null,
        );
      }).toList(),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: Icon(icon)),
        child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
