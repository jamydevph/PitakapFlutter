import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/router/main_shell.dart';
import 'package:pitakapflutter/feature/auth/presentation/forgot_password/forgot_password_page.dart';
import 'package:pitakapflutter/feature/auth/presentation/login/login_page.dart';
import 'package:pitakapflutter/feature/auth/presentation/sign_up/sign_up_page.dart';
import 'package:pitakapflutter/feature/dashboard/presentation/dashboard_page.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/presentation/expense_edit_page.dart';
import 'package:pitakapflutter/feature/expense/presentation/expenses_page.dart';
import 'package:pitakapflutter/feature/history/presentation/history_page.dart';
import 'package:pitakapflutter/feature/onboarding/presentation/onboarding_page.dart';
import 'package:pitakapflutter/feature/profile/presentation/settings_page.dart';
import 'package:pitakapflutter/feature/splash/presentation/splash_page.dart';
import 'package:pitakapflutter/feature/stats/presentation/stats_page.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/presentation/subscription_detail_page.dart';
import 'package:pitakapflutter/feature/subscription/presentation/subscription_edit_page.dart';
import 'package:pitakapflutter/feature/subscription/presentation/subscriptions_list_page.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/presentation/wallet_edit_page.dart';
import 'package:pitakapflutter/feature/wallet/presentation/wallets_page.dart';

StatefulShellBranch _branch(String path, Widget page) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => page)],
  );
}

const Set<String> _publicRoutes = {
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.signUp,
  AppRoutes.forgotPassword,
};

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AsyncValue<String?>>(const AsyncLoading());
  ref.listen(authStateProvider, (_, next) => refresh.value = next);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == AppRoutes.splash) return null;

      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;

      final isSignedIn = authState.value != null;
      final isPublic = _publicRoutes.contains(location);

      if (!isSignedIn) return isPublic ? null : AppRoutes.login;
      if (isPublic) return AppRoutes.dashboard;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => ForgotPasswordPage(
          initialEmail: state.uri.queryParameters[AppRoutes.emailQueryParam],
        ),
      ),
      GoRoute(
        path: AppRoutes.subscriptionNew,
        builder: (context, state) => SubscriptionEditPage(
          subscription: state.extra as SubscriptionEntity?,
        ),
      ),
      GoRoute(
        path: AppRoutes.subscriptionDetail,
        builder: (context, state) => SubscriptionDetailPage(
          subscriptionId:
              state.pathParameters[AppRoutes.subscriptionIdParam] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.expenseNew,
        builder: (context, state) =>
            ExpenseEditPage(expense: state.extra as ExpenseEntity?),
      ),
      GoRoute(
        path: AppRoutes.walletNew,
        builder: (context, state) =>
            WalletEditPage(wallet: state.extra as WalletEntity?),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          _branch(AppRoutes.dashboard, const DashboardPage()),
          _branch(AppRoutes.subscriptions, const SubscriptionsListPage()),
          _branch(AppRoutes.expenses, const ExpensesPage()),
          _branch(AppRoutes.stats, const StatsPage()),
          _branch(AppRoutes.settings, const SettingsPage()),
          _branch(AppRoutes.wallets, const WalletsPage()),
          _branch(AppRoutes.history, const HistoryPage()),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);

  return router;
});
