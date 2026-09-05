import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';

String subscriptionAvatarTag(String subscriptionId) =>
    'subscription-avatar-$subscriptionId';

class SubscriptionTile extends StatelessWidget {
  final SubscriptionEntity subscription;
  final DateTime now;
  final VoidCallback? onTap;

  const SubscriptionTile({
    super.key,
    required this.subscription,
    required this.now,
    this.onTap,
  });

  static const int soonThresholdDays = 3;

  static String dueLabel(
    int daysUntil,
    DateTime dueDate, {
    int wordsWithinDays = soonThresholdDays,
  }) {
    if (daysUntil <= 0) return Strings.dueToday;
    if (daysUntil == 1) return Strings.dueTomorrow;
    if (daysUntil <= wordsWithinDays) return 'in $daysUntil days';

    return DateFormat('MMM d').format(dueDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accent = AppColors.categoryAccent(subscription.category);
    final dueDate = subscription.nextDueDateAsOf(now);
    final daysUntil = subscription.daysUntilNextDueAsOf(now);
    final isSoon = daysUntil <= soonThresholdDays;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Hero(
                tag: subscriptionAvatarTag(subscription.id),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: accent,
                  child: Text(
                    subscription.name.isEmpty
                        ? '?'
                        : subscription.name.characters.first.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subscription.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${formatCurrency(subscription.monthlyCost, currencyCode: subscription.currency)}'
                    '${Strings.perMonthSuffix}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _DueBadge(
                    label: dueLabel(daysUntil, dueDate),
                    background: isSoon
                        ? colorScheme.error.withValues(alpha: 0.14)
                        : colorScheme.primaryContainer,
                    foreground: isSoon
                        ? colorScheme.error
                        : colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _DueBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
