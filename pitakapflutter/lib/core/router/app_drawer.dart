import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/feature/auth/domain/entities/user_details_entity.dart';

class DrawerDestination {
  final IconData icon;
  final String label;
  final String route;

  const DrawerDestination({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();

  static const List<DrawerDestination> destinations = [
    DrawerDestination(
      icon: Icons.home_outlined,
      label: Strings.navDashboard,
      route: AppRoutes.dashboard,
    ),
    DrawerDestination(
      icon: Icons.autorenew_outlined,
      label: Strings.navSubscriptions,
      route: AppRoutes.subscriptions,
    ),
    DrawerDestination(
      icon: Icons.receipt_long_outlined,
      label: Strings.navExpenses,
      route: AppRoutes.expenses,
    ),
    DrawerDestination(
      icon: Icons.history_outlined,
      label: Strings.navHistory,
      route: AppRoutes.history,
    ),
    DrawerDestination(
      icon: Icons.pie_chart_outline,
      label: Strings.navStats,
      route: AppRoutes.stats,
    ),
    DrawerDestination(
      icon: Icons.account_balance_wallet_outlined,
      label: Strings.navWallets,
      route: AppRoutes.wallets,
    ),
    DrawerDestination(
      icon: Icons.settings_outlined,
      label: Strings.navSettings,
      route: AppRoutes.settings,
    ),
  ];

  static int selectedIndexFor(String location) {
    final index = destinations.indexWhere(
      (destination) => location.startsWith(destination.route),
    );

    return index < 0 ? 0 : index;
  }
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  void _select(DrawerDestination destination) {
    final router = GoRouter.of(context);
    final isCurrent =
        GoRouterState.of(context).matchedLocation == destination.route;

    Navigator.of(context).pop();

    if (isCurrent) return;

    router.go(destination.route);
  }

  Future<void> _signOut() async {
    final messenger = ScaffoldMessenger.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final signOut = ref.read(signOutUseCaseProvider);

    Navigator.of(context).pop();

    final confirmed = await CommonConfirmDialog.show(
      rootContext,
      title: Strings.signOutTitle,
      message: Strings.signOutMessage,
      confirmLabel: Strings.signOutAction,
      isDestructive: false,
    );

    if (!confirmed) return;

    try {
      await signOut.call();
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failureMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value;
    final details = uid == null
        ? null
        : ref.watch(userDetailsProvider(uid)).value;
    final location = GoRouterState.of(context).matchedLocation;

    return NavigationDrawer(
      selectedIndex: AppDrawer.selectedIndexFor(location),
      onDestinationSelected: (index) => _select(AppDrawer.destinations[index]),
      footer: _SignOutButton(onPressed: _signOut),
      children: [
        _DrawerHeader(details: details),
        for (final destination in AppDrawer.destinations)
          NavigationDrawerDestination(
            icon: Icon(destination.icon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SignOutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: CommonPrimaryButton(
          label: Strings.signOutAction,
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final UserDetailsEntity? details;

  const _DrawerHeader({required this.details});

  static String initialsOf(UserDetailsEntity? details) {
    if (details == null) return '';

    final first = details.firstName.isEmpty ? '' : details.firstName[0];
    final last = details.lastName.isEmpty ? '' : details.lastName[0];
    final initials = '$first$last'.toUpperCase();

    return initials.isEmpty ? '?' : initials;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = details?.fullName ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl + AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              initialsOf(details),
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                if (details != null)
                  Text(
                    details!.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
