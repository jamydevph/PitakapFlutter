import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/subscription_providers.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/core/utils/label_format.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/presentation/widgets/subscription_tile.dart';
import 'package:pitakapflutter/feature/subscription/presentation/providers/subscription_edit_controller.dart';
import 'package:pitakapflutter/feature/subscription/presentation/providers/subscription_edit_state.dart';
import 'package:pitakapflutter/feature/subscription/presentation/subscription_edit_page.dart';

class SubscriptionDetailPage extends ConsumerStatefulWidget {
  final String subscriptionId;

  const SubscriptionDetailPage({super.key, required this.subscriptionId});

  static const int upcomingCount = 3;

  static final DateFormat dateFormat = DateFormat('MMM d, yyyy');

  @override
  ConsumerState<SubscriptionDetailPage> createState() =>
      _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState
    extends ConsumerState<SubscriptionDetailPage> {
  SubscriptionEntity? _lastKnown;
  bool _isDeleting = false;

  SubscriptionEntity? _findById(List<SubscriptionEntity> subscriptions) {
    for (final subscription in subscriptions) {
      if (subscription.id == widget.subscriptionId) return subscription;
    }

    return null;
  }

  Future<void> _confirmDelete(SubscriptionEntity subscription) async {
    final confirmed = await CommonConfirmDialog.show(
      context,
      title: Strings.deleteSubscriptionTitle,
      message: Strings.deleteSubscriptionMessage,
    );

    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(subscriptionEditControllerProvider.notifier);

    setState(() => _isDeleting = true);

    await controller.delete(subscription.id);

    if (!mounted) return;

    final result = ref.read(subscriptionEditControllerProvider).value;
    controller.reset();

    if (result is SubscriptionEditDeletedState) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.subscriptions);
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${subscription.name} ${Strings.subscriptionDeleted}',
            ),
          ),
        );
      return;
    }

    setState(() => _isDeleting = false);

    if (result is SubscriptionEditFailedState) {
      CommonSnackBar.showError(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(subscriptionEditControllerProvider.notifier);

    final userId = ref.watch(authStateProvider).value;

    if (userId == null) {
      return const Scaffold(body: CommonLoader.page());
    }

    return ref
        .watch(subscriptionsStreamProvider(userId))
        .when(
          loading: () => const Scaffold(body: CommonLoader.page()),
          error: (error, _) => _Shell(
            child: CommonEmptyState(
              icon: Icons.cloud_off_outlined,
              title: Strings.subscriptionsLoadFailed,
              message: failureMessage(error),
            ),
          ),
          data: (subscriptions) {
            final found = _findById(subscriptions);
            if (found != null) _lastKnown = found;

            final subscription = found ?? (_isDeleting ? _lastKnown : null);

            if (subscription == null) {
              return const _Shell(
                child: CommonEmptyState(
                  icon: Icons.search_off_outlined,
                  title: Strings.subscriptionNotFound,
                  message: Strings.subscriptionNotFoundMessage,
                ),
              );
            }

            return _Shell(
              child: _DetailBody(
                subscription: subscription,
                isDeleting: _isDeleting,
                onEdit: () => context.push(
                  AppRoutes.subscriptionNew,
                  extra: subscription,
                ),
                onDelete: () => _confirmDelete(subscription),
              ),
            );
          },
        );
  }
}

class _Shell extends StatelessWidget {
  final Widget child;

  const _Shell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(Strings.subscriptionDetailTitle),
      ),
      body: SafeArea(child: child),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final SubscriptionEntity subscription;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailBody({
    required this.subscription,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final renewals = subscription.upcomingDueDatesAsOf(
      now,
      count: SubscriptionDetailPage.upcomingCount,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        _Header(subscription: subscription),
        const SizedBox(height: AppSpacing.lg),
        _CostCard(subscription: subscription),
        const SizedBox(height: AppSpacing.md),
        _InfoCard(subscription: subscription, now: now),
        const SizedBox(height: AppSpacing.md),
        _RenewalsCard(subscription: subscription, renewals: renewals),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: isDeleting ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text(Strings.editAction),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: isDeleting ? null : onDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          icon: isDeleting
              ? const CommonLoader(size: 18)
              : const Icon(Icons.delete_outline),
          label: const Text(Strings.deleteAction),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final SubscriptionEntity subscription;

  const _Header({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.categoryAccent(subscription.category);

    return Column(
      children: [
        Hero(
          tag: subscriptionAvatarTag(subscription.id),
          child: CircleAvatar(
            radius: 36,
            backgroundColor: accent,
            child: Text(
              subscription.name.isEmpty
                  ? '?'
                  : subscription.name.characters.first.toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          subscription.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${categoryLabel(subscription.category)} · '
          '${subscription.billingCycle.label}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _CostCard extends StatelessWidget {
  final SubscriptionEntity subscription;

  const _CostCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _CostColumn(
                  amount: formatCurrency(
                    subscription.monthlyCost,
                    currencyCode: subscription.currency,
                  ),
                  label: Strings.perMonthLabel,
                  color: colorScheme.onSurface,
                ),
              ),
              const VerticalDivider(width: 1, indent: 4, endIndent: 4),
              Expanded(
                child: _CostColumn(
                  amount: formatCurrency(
                    subscription.yearlyCost,
                    currencyCode: subscription.currency,
                    decimalDigits: 0,
                  ),
                  label: Strings.perYearLabel,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostColumn extends StatelessWidget {
  final String amount;
  final String label;
  final Color color;

  const _CostColumn({
    required this.amount,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(color: color),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final SubscriptionEntity subscription;
  final DateTime now;

  const _InfoCard({required this.subscription, required this.now});

  @override
  Widget build(BuildContext context) {
    final format = SubscriptionDetailPage.dateFormat;

    return Card(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.event_outlined,
            label: Strings.nextPaymentLabel,
            value: format.format(subscription.nextDueDateAsOf(now)),
          ),
          const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
          _InfoRow(
            icon: Icons.notifications_none_outlined,
            label: Strings.reminderRowLabel,
            value: SubscriptionEditPage.reminderLabel(
              subscription.reminderDaysBefore,
            ),
          ),
          const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
          _InfoRow(
            icon: Icons.history_outlined,
            label: Strings.firstBilledLabel,
            value: format.format(subscription.firstBillDate),
          ),
          if (subscription.notes.isNotEmpty) ...[
            const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
            _InfoRow(
              icon: Icons.notes_outlined,
              label: Strings.subscriptionNotesLabel,
              value: subscription.notes,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewalsCard extends StatelessWidget {
  final SubscriptionEntity subscription;
  final List<DateTime> renewals;

  const _RenewalsCard({required this.subscription, required this.renewals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = SubscriptionDetailPage.dateFormat;

    final amount = formatCurrency(
      subscription.amount,
      currencyCode: subscription.currency,
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Strings.upcomingRenewalsLabel,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final renewal in renewals)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        format.format(renewal),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Text(amount, style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
