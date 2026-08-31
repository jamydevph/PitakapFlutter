import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/settings_providers.dart';
import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/core/utils/label_format.dart';
import 'package:pitakapflutter/core/utils/validators.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/presentation/providers/subscription_edit_controller.dart';
import 'package:pitakapflutter/feature/subscription/presentation/providers/subscription_edit_state.dart';

class SubscriptionEditPage extends ConsumerStatefulWidget {
  final SubscriptionEntity? subscription;

  const SubscriptionEditPage({super.key, this.subscription});

  static const List<int> reminderOptions = [0, 1, 2, 3, 5, 7];

  static String reminderLabel(int daysBefore) {
    if (daysBefore <= 0) return Strings.reminderSameDay;
    if (daysBefore == 1) return Strings.reminderOneDay;

    return '$daysBefore days before';
  }

  @override
  ConsumerState<SubscriptionEditPage> createState() =>
      _SubscriptionEditPageState();
}

class _SubscriptionEditPageState extends ConsumerState<SubscriptionEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late String _category;
  late BillingCycle _cycle;
  late DateTime _firstBillDate;
  late int _reminderDaysBefore;

  bool get _isEditing => widget.subscription != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.subscription;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _category = existing?.category ?? Constants.subscriptionCategories.first;
    _cycle = existing?.billingCycle ?? BillingCycle.monthly;
    _firstBillDate = existing?.firstBillDate ?? DateTime.now();
    _reminderDaysBefore =
        existing?.reminderDaysBefore ?? ref.read(defaultReminderDaysProvider);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFirstBillDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstBillDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) setState(() => _firstBillDate = picked);
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppRoutes.subscriptions);
  }

  void _save(String userId) {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) return;

    final amount = double.parse(_amountController.text.trim());
    final controller = ref.read(subscriptionEditControllerProvider.notifier);
    final existing = widget.subscription;

    if (existing == null) {
      controller.create(
        CreateSubscriptionUseCaseParams(
          userId: userId,
          name: _nameController.text.trim(),
          category: _category,
          amount: amount,
          firstBillDate: _firstBillDate,
          billingCycle: _cycle,
          currency: ref.read(defaultCurrencyProvider),
          reminderDaysBefore: _reminderDaysBefore,
          notes: _notesController.text.trim(),
        ),
      );
      return;
    }

    controller.updateExisting(
      SubscriptionEntity(
        id: existing.id,
        userId: existing.userId,
        name: _nameController.text.trim(),
        category: _category,
        amount: amount,
        firstBillDate: _firstBillDate,
        billingCycle: _cycle,
        currency: existing.currency,
        reminderDaysBefore: _reminderDaysBefore,
        colorHex: existing.colorHex,
        iconKey: existing.iconKey,
        notes: _notesController.text.trim(),
        isActive: existing.isActive,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editState = ref.watch(subscriptionEditControllerProvider).value;
    final isBusy = editState is SubscriptionEditLoadingState;
    final userId = ref.watch(authStateProvider).value;
    final String currencyCode =
        widget.subscription?.currency ?? ref.watch(defaultCurrencyProvider);

    ref.listen(subscriptionEditControllerProvider, (previous, next) {
      final state = next.value;

      if (state is SubscriptionEditFailedState) {
        CommonSnackBar.showError(context, state.message);
        ref.read(subscriptionEditControllerProvider.notifier).reset();
        return;
      }

      if (state is SubscriptionEditSuccessState) {
        CommonSnackBar.showSuccess(
          context,
          state.wasExisting
              ? Strings.subscriptionUpdated
              : Strings.subscriptionCreated,
        );
        ref.read(subscriptionEditControllerProvider.notifier).reset();
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
                          ? Strings.subscriptionEditTitle
                          : Strings.subscriptionAddTitle,
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
                    CommonTextField(
                      controller: _nameController,
                      label: Strings.subscriptionNameLabel,
                      hint: Strings.subscriptionNameHint,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      enabled: !isBusy,
                      validator: (value) => Validators.notEmpty(
                        value,
                        Strings.subscriptionNameRequired,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionLabel(Strings.subscriptionCategoryLabel),
                    _ChoiceChips<String>(
                      values: Constants.subscriptionCategories,
                      selected: _category,
                      labelOf: categoryLabel,
                      enabled: !isBusy,
                      onSelected: (value) => setState(() => _category = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionLabel(Strings.subscriptionCycleLabel),
                    _ChoiceChips<BillingCycle>(
                      values: BillingCycle.values,
                      selected: _cycle,
                      labelOf: (value) => value.label,
                      enabled: !isBusy,
                      onSelected: (value) => setState(() => _cycle = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _PickerField(
                      label: Strings.subscriptionFirstBillLabel,
                      value: DateFormat('MMM d, y').format(_firstBillDate),
                      icon: Icons.calendar_today_outlined,
                      onTap: isBusy ? null : _pickFirstBillDate,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionLabel(Strings.subscriptionReminderLabel),
                    _ChoiceChips<int>(
                      values: SubscriptionEditPage.reminderOptions,
                      selected: _reminderDaysBefore,
                      labelOf: SubscriptionEditPage.reminderLabel,
                      enabled: !isBusy,
                      onSelected: (value) =>
                          setState(() => _reminderDaysBefore = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CommonTextField(
                      controller: _notesController,
                      label: Strings.subscriptionNotesLabel,
                      hint: Strings.subscriptionNotesHint,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !isBusy,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CommonPrimaryButton(
                label: Strings.subscriptionSaveAction,
                onPressed: userId == null ? null : () => _save(userId),
                isLoading: isBusy,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
          Text(
            Strings.subscriptionAmountLabel,
            style: theme.textTheme.labelMedium,
          ),
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
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
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
