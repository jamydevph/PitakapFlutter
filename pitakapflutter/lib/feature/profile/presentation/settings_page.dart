import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/settings_providers.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/feature/auth/domain/entities/user_details_entity.dart';
import 'package:pitakapflutter/feature/profile/presentation/widgets/settings_section.dart';

String reminderDaysLabel(int days) {
  if (days <= 0) return Strings.reminderSameDay;
  if (days == 1) return Strings.reminderOneDay;

  return '$days days before';
}

String currencyLabel(String code) => '$code  ${currencySymbol(code)}';

String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.light => Strings.settingsThemeLight,
  ThemeMode.dark => Strings.settingsThemeDark,
  ThemeMode.system => Strings.settingsThemeSystem,
};

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isBusy = false;

  Future<void> _signOut() async {
    if (_isBusy) return;

    final confirmed = await CommonConfirmDialog.show(
      context,
      title: Strings.signOutTitle,
      message: Strings.signOutMessage,
      confirmLabel: Strings.signOutAction,
      isDestructive: false,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isBusy = true);

    try {
      await ref.read(signOutUseCaseProvider).call();
    } catch (error) {
      if (!mounted) return;
      CommonSnackBar.showError(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteAccount() async {
    if (_isBusy) return;

    final confirmed = await CommonConfirmDialog.show(
      context,
      title: Strings.deleteAccountTitle,
      message: Strings.deleteAccountMessage,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isBusy = true);

    try {
      await ref.read(deleteAccountUseCaseProvider).call();
    } catch (error) {
      if (!mounted) return;
      CommonSnackBar.showError(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _pickCurrency() async {
    final selected = await _pickOption<String>(
      title: Strings.settingsCurrencyLabel,
      options: Constants.currencies,
      current: ref.read(defaultCurrencyProvider),
      labelOf: currencyLabel,
    );

    if (selected == null) return;

    await ref.read(defaultCurrencyProvider.notifier).setCurrency(selected);
  }

  Future<void> _pickReminderDays() async {
    final selected = await _pickOption<int>(
      title: Strings.settingsReminderLabel,
      options: Constants.reminderDayOptions,
      current: ref.read(defaultReminderDaysProvider),
      labelOf: reminderDaysLabel,
    );

    if (selected == null) return;

    await ref.read(defaultReminderDaysProvider.notifier).setDays(selected);
  }

  Future<void> _pickThemeMode() async {
    final selected = await _pickOption<ThemeMode>(
      title: Strings.settingsThemeLabel,
      options: ThemeMode.values,
      current: ref.read(themeModeProvider),
      labelOf: themeModeLabel,
    );

    if (selected == null) return;

    await ref.read(themeModeProvider.notifier).setThemeMode(selected);
  }

  Future<T?> _pickOption<T>({
    required String title,
    required List<T> options,
    required T current,
    required String Function(T value) labelOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioGroup<T>(
              groupValue: current,
              onChanged: (value) => Navigator.of(context).pop(value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in options)
                    RadioListTile<T>(
                      value: option,
                      title: Text(labelOf(option)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value;
    final details = uid == null
        ? null
        : ref.watch(userDetailsProvider(uid)).value;

    final currency = ref.watch(defaultCurrencyProvider);
    final reminderDays = ref.watch(defaultReminderDaysProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl * 2,
        ),
        children: [
          _ProfileHeader(details: details),
          const SizedBox(height: AppSpacing.lg),
          SettingsSection(
            title: Strings.settingsPreferencesSection,
            children: [
              SettingsTile(
                icon: Icons.payments_outlined,
                label: Strings.settingsCurrencyLabel,
                hint: Strings.settingsCurrencyHint,
                value: currencyLabel(currency),
                onTap: _isBusy ? null : _pickCurrency,
              ),
              SettingsTile(
                icon: Icons.notifications_active_outlined,
                label: Strings.settingsReminderLabel,
                hint: Strings.settingsReminderHint,
                value: reminderDaysLabel(reminderDays),
                onTap: _isBusy ? null : _pickReminderDays,
              ),
              SettingsTile(
                icon: Icons.brightness_6_outlined,
                label: Strings.settingsThemeLabel,
                value: themeModeLabel(themeMode),
                onTap: _isBusy ? null : _pickThemeMode,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsSection(
            title: Strings.settingsAccountSection,
            children: [
              SettingsTile(
                icon: Icons.logout_outlined,
                label: Strings.signOutAction,
                onTap: _isBusy ? null : _signOut,
              ),
              SettingsTile(
                icon: Icons.delete_outline,
                label: Strings.deleteAccountAction,
                isDestructive: true,
                onTap: _isBusy ? null : _deleteAccount,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsSection(
            title: Strings.settingsAboutSection,
            children: [
              SettingsTile(
                icon: Icons.info_outline,
                label: Strings.settingsAppNameLabel,
                value: '${Strings.settingsVersionLabel} '
                    '${Constants.appVersion}',
              ),
            ],
          ),
          if (_isBusy) ...[
            const SizedBox(height: AppSpacing.lg),
            const CommonLoader(size: 20),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserDetailsEntity? details;

  const _ProfileHeader({required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = details == null
        ? ''
        : '${details!.firstName} ${details!.lastName}'.trim();

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            _initials(details),
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty)
                Text(name, style: theme.textTheme.titleMedium),
              if (details != null)
                Text(
                  details!.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _initials(UserDetailsEntity? details) {
    if (details == null) return '';

    final first = details.firstName.isEmpty ? '' : details.firstName[0];
    final last = details.lastName.isEmpty ? '' : details.lastName[0];
    final initials = '$first$last'.toUpperCase();

    return initials.isEmpty ? '?' : initials;
  }
}
