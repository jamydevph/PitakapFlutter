import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/subscription_providers.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/restore_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/presentation/providers/subscription_list_filter.dart';
import 'package:pitakapflutter/feature/subscription/presentation/providers/subscription_list_filter_controller.dart';
import 'package:pitakapflutter/feature/subscription/presentation/widgets/subscription_filter_bar.dart';
import 'package:pitakapflutter/feature/subscription/presentation/widgets/subscription_tile.dart';

class SubscriptionsListPage extends ConsumerWidget {
  const SubscriptionsListPage({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SubscriptionEntity subscription,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(deleteSubscriptionUseCaseProvider)
          .call(DeleteSubscriptionUseCaseParams(subscription.id));
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
          content: Text('${subscription.name} ${Strings.subscriptionDeleted}'),
          action: SnackBarAction(
            label: Strings.undoAction,
            onPressed: () => _restore(context, ref, subscription),
          ),
        ),
      );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    SubscriptionEntity subscription,
  ) async {
    try {
      await ref
          .read(restoreSubscriptionUseCaseProvider)
          .call(RestoreSubscriptionUseCaseParams(subscription));
    } catch (error) {
      if (!context.mounted) return;
      CommonSnackBar.showError(context, failureMessage(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value;
    final filter = ref.watch(subscriptionListFilterProvider);
    final controller = ref.read(subscriptionListFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.subscriptionsTitle),
        actions: [
          PopupMenuButton<SubscriptionSort>(
            icon: const Icon(Icons.swap_vert),
            tooltip: Strings.sortAction,
            initialValue: filter.sort,
            onSelected: controller.selectSort,
            itemBuilder: (context) => [
              for (final sort in SubscriptionSort.values)
                PopupMenuItem(value: sort, child: Text(sort.label)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.subscriptionNew),
        child: const Icon(Icons.add),
      ),
      body: userId == null
          ? const CommonLoader.page()
          : ref
                .watch(subscriptionsStreamProvider(userId))
                .when(
                  loading: () => const CommonLoader.page(),
                  error: (error, _) => CommonEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: Strings.subscriptionsLoadFailed,
                    message: failureMessage(error),
                  ),
                  data: (subscriptions) => subscriptions.isEmpty
                      ? const CommonEmptyState(
                          icon: Icons.autorenew_outlined,
                          title: Strings.subscriptionsEmptyTitle,
                          message: Strings.subscriptionsEmptyMessage,
                        )
                      : _FilteredList(
                          subscriptions: subscriptions,
                          filter: filter,
                          onSelectCategory: controller.selectCategory,
                          onDelete: (subscription) =>
                              _delete(context, ref, subscription),
                          onOpen: (subscription) => context.push(
                            AppRoutes.subscriptionDetailPath(subscription.id),
                          ),
                        ),
                ),
    );
  }
}

class _FilteredList extends StatelessWidget {
  final List<SubscriptionEntity> subscriptions;
  final SubscriptionListFilter filter;
  final ValueChanged<String?> onSelectCategory;
  final ValueChanged<SubscriptionEntity> onDelete;
  final ValueChanged<SubscriptionEntity> onOpen;

  const _FilteredList({
    required this.subscriptions,
    required this.filter,
    required this.onSelectCategory,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final visible = applyListFilter(subscriptions, filter: filter, now: now);

    return Column(
      children: [
        SubscriptionFilterBar(
          categories: availableCategories(subscriptions),
          selected: filter.category,
          onSelected: onSelectCategory,
        ),
        Expanded(
          child: visible.isEmpty
              ? CommonEmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: Strings.subscriptionsFilterEmptyTitle,
                  message: Strings.subscriptionsFilterEmptyMessage,
                  actionLabel: Strings.showAllAction,
                  onAction: () => onSelectCategory(null),
                )
              : _SubscriptionList(
                  subscriptions: visible,
                  now: now,
                  onDelete: onDelete,
                  onOpen: onOpen,
                ),
        ),
      ],
    );
  }
}

class _SubscriptionList extends StatelessWidget {
  final List<SubscriptionEntity> subscriptions;
  final DateTime now;
  final ValueChanged<SubscriptionEntity> onDelete;
  final ValueChanged<SubscriptionEntity> onOpen;

  const _SubscriptionList({
    required this.subscriptions,
    required this.now,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl * 2,
      ),
      itemCount: subscriptions.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final subscription = subscriptions[index];

        return Dismissible(
          key: ValueKey(subscription.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDelete(subscription),
          background: const _DeleteBackground(),
          child: SubscriptionTile(
            subscription: subscription,
            now: now,
            onTap: () => onOpen(subscription),
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
