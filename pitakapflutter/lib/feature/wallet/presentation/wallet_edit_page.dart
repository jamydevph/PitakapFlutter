import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/settings_providers.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/amount_input_formatter.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/core/utils/validators.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/presentation/providers/wallet_edit_controller.dart';
import 'package:pitakapflutter/feature/wallet/presentation/providers/wallet_edit_state.dart';

class WalletEditPage extends ConsumerStatefulWidget {
  final WalletEntity? wallet;

  const WalletEditPage({super.key, this.wallet});

  @override
  ConsumerState<WalletEditPage> createState() => _WalletEditPageState();
}

class _WalletEditPageState extends ConsumerState<WalletEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _balanceController;

  bool get _isEditing => widget.wallet != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.wallet;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _balanceController = TextEditingController(
      text: existing == null ? '' : existing.openingBalance.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppRoutes.wallets);
  }

  void _save(String userId) {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final openingBalance = double.parse(_balanceController.text.trim());
    final controller = ref.read(walletEditControllerProvider.notifier);
    final existing = widget.wallet;

    if (existing == null) {
      controller.create(
        CreateWalletUseCaseParams(
          userId: userId,
          name: name,
          openingBalance: openingBalance,
          description: description,
          currency: ref.read(defaultCurrencyProvider),
        ),
      );
      return;
    }

    controller.updateExisting(
      WalletEntity(
        id: existing.id,
        userId: existing.userId,
        name: name,
        openingBalance: openingBalance,
        description: description,
        currency: existing.currency,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editState = ref.watch(walletEditControllerProvider).value;
    final isBusy = editState is WalletEditLoadingState;
    final userId = ref.watch(authStateProvider).value;
    final String currencyCode =
        widget.wallet?.currency ?? ref.watch(defaultCurrencyProvider);

    ref.listen(walletEditControllerProvider, (previous, next) {
      final state = next.value;

      if (state is WalletEditFailedState) {
        CommonSnackBar.showError(context, state.message);
        ref.read(walletEditControllerProvider.notifier).reset();
        return;
      }

      if (state is WalletEditSuccessState) {
        CommonSnackBar.showSuccess(
          context,
          state.wasExisting ? Strings.walletUpdated : Strings.walletCreated,
        );
        ref.read(walletEditControllerProvider.notifier).reset();
        _close();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: isBusy ? null : _close,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          _isEditing ? Strings.walletEditTitle : Strings.walletAddTitle,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                    CommonTextField(
                      controller: _nameController,
                      label: Strings.walletNameLabel,
                      hint: Strings.walletNameHint,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      enabled: !isBusy,
                      validator: (value) => Validators.notEmpty(
                        value,
                        Strings.walletNameRequired,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CommonTextField(
                      controller: _descriptionController,
                      label: Strings.walletDescriptionLabel,
                      hint: Strings.walletDescriptionHint,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      enabled: !isBusy,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _balanceController,
                      enabled: !isBusy,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      inputFormatters: const [AmountInputFormatter()],
                      decoration: InputDecoration(
                        labelText: Strings.walletOpeningBalanceLabel,
                        hintText: formatCurrency(0, currencyCode: currencyCode),
                      ),
                      validator: Validators.amount,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      Strings.walletOpeningBalanceHelp,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CommonPrimaryButton(
                label: Strings.walletSaveAction,
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
