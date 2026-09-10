import 'package:flutter/material.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/currency_format.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';

class WalletTile extends StatelessWidget {
  final WalletEntity wallet;
  final double available;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const WalletTile({
    super.key,
    required this.wallet,
    required this.available,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOverdrawn = available < 0;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (wallet.hasDescription) ...[
                      const SizedBox(height: 2),
                      Text(
                        wallet.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatCurrency(available, currencyCode: wallet.currency),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isOverdrawn ? colorScheme.error : colorScheme.primary,
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
