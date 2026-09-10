abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';

  static const String subscriptionNew = '/subscription/new';
  static const String subscriptionIdParam = 'id';
  static const String subscriptionDetail = '/subscription/detail/:id';

  static String subscriptionDetailPath(String id) => '/subscription/detail/$id';

  static const String expenseNew = '/expense/new';

  static const String emailQueryParam = 'email';
  static const String dashboard = '/dashboard';
  static const String subscriptions = '/subscriptions';
  static const String expenses = '/expenses';
  static const String stats = '/stats';
  static const String settings = '/settings';
  static const String wallets = '/wallets';
  static const String history = '/history';

  static const String walletNew = '/wallet/new';
}
