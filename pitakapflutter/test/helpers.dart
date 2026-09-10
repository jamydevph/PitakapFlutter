import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pitakapflutter/core/providers/app_providers.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/expense_providers.dart';
import 'package:pitakapflutter/core/providers/subscription_providers.dart';
import 'package:pitakapflutter/core/providers/wallet_providers.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/keys.dart';
import 'package:pitakapflutter/core/router/app_router.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/feature/auth/domain/entities/user_details_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/restore_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/update_wallet_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/repository/auth_repository.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/login_user_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:pitakapflutter/feature/auth/domain/usecases/sign_up_user_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/entities/expense_entity.dart';
import 'package:pitakapflutter/feature/expense/domain/repository/expense_repository.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/create_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/delete_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/restore_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/update_expense_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_day_usecase.dart';
import 'package:pitakapflutter/feature/expense/domain/usecases/watch_expenses_for_month_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/repository/subscription_repository.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/restore_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/update_subscription_usecase.dart';
import 'package:pitakapflutter/main.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const Map<String, Object> onboarded = {Keys.prefsOnboardingSeen: true};

const testUser = UserDetailsEntity(
  uid: 'uid-1',
  firstName: 'Diane',
  lastName: 'Magno',
  email: 'diane@pitakap.app',
);

void registerAuthFallbacks() {
  registerFallbackValue(const LoginUseCaseParams(email: '', password: ''));
  registerFallbackValue(
    const SignUpUseCaseParams(
      firstName: '',
      lastName: '',
      email: '',
      password: '',
    ),
  );
  registerFallbackValue(const SendPasswordResetUseCaseParams(email: ''));
}

List<Override> authOverrides({
  String? signedInUid,
  AuthRepository? repository,
  UserDetailsEntity? userDetails = testUser,
}) {
  return [
    authStateProvider.overrideWith((ref) => Stream.value(signedInUid)),
    userDetailsProvider.overrideWith((ref, uid) => Stream.value(userDetails)),
    if (repository != null)
      authRepositoryProvider.overrideWithValue(repository),
  ];
}

class EmptySubscriptionRepository implements SubscriptionRepository {
  const EmptySubscriptionRepository();

  @override
  Stream<List<SubscriptionEntity>> watchSubscriptions(String userId) {
    return Stream.value(const []);
  }

  @override
  Future<void> createSubscription(
    CreateSubscriptionUseCaseParams params,
  ) async {}

  @override
  Future<void> updateSubscription(
    UpdateSubscriptionUseCaseParams params,
  ) async {}

  @override
  Future<void> deleteSubscription(
    DeleteSubscriptionUseCaseParams params,
  ) async {}

  @override
  Future<void> restoreSubscription(
    RestoreSubscriptionUseCaseParams params,
  ) async {}

  @override
  Future<void> rescheduleAllReminders(String userId) async {}
}

class EmptyExpenseRepository implements ExpenseRepository {
  const EmptyExpenseRepository();

  @override
  Stream<List<ExpenseEntity>> watchAllExpenses(String userId) {
    return Stream.value(const []);
  }

  @override
  Stream<List<ExpenseEntity>> watchExpensesForDay(
    WatchExpensesForDayParams params,
  ) {
    return Stream.value(const []);
  }

  @override
  Stream<List<ExpenseEntity>> watchExpensesForMonth(
    WatchExpensesForMonthParams params,
  ) {
    return Stream.value(const []);
  }

  @override
  Future<void> createExpense(CreateExpenseUseCaseParams params) async {}

  @override
  Future<void> updateExpense(UpdateExpenseUseCaseParams params) async {}

  @override
  Future<void> deleteExpense(DeleteExpenseUseCaseParams params) async {}

  @override
  Future<void> restoreExpense(RestoreExpenseUseCaseParams params) async {}
}

class EmptyWalletRepository implements WalletRepository {
  const EmptyWalletRepository();

  @override
  Stream<List<WalletEntity>> watchWallets(String userId) {
    return Stream.value(const []);
  }

  @override
  Future<void> createWallet(CreateWalletUseCaseParams params) async {}

  @override
  Future<void> updateWallet(UpdateWalletUseCaseParams params) async {}

  @override
  Future<void> deleteWallet(DeleteWalletUseCaseParams params) async {}

  @override
  Future<void> restoreWallet(RestoreWalletUseCaseParams params) async {}
}

List<Override> featureOverrides({
  SubscriptionRepository? subscriptions,
  ExpenseRepository? expenses,
  WalletRepository? wallets,
}) {
  return [
    subscriptionRepositoryProvider.overrideWithValue(
      subscriptions ?? const EmptySubscriptionRepository(),
    ),
    expenseRepositoryProvider.overrideWithValue(
      expenses ?? const EmptyExpenseRepository(),
    ),
    walletRepositoryProvider.overrideWithValue(
      wallets ?? const EmptyWalletRepository(),
    ),
  ];
}

Future<ProviderContainer> containerWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

Future<ProviderContainer> containerWithAuth(AuthRepository repository) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

Future<Widget> appWith(
  Map<String, Object> values, {
  String? signedInUid,
}) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...authOverrides(signedInUid: signedInUid),
      ...featureOverrides(),
    ],
    child: const PitakapApp(),
  );
}

Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  Brightness brightness = Brightness.light,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpPastSplash(WidgetTester tester) async {
  await tester.pump(Constants.splashMinimumDuration);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> pumpAppAt(
  WidgetTester tester,
  String location, {
  Map<String, Object> values = onboarded,
  String? signedInUid,
  AuthRepository? repository,
  UserDetailsEntity? userDetails = testUser,
  SubscriptionRepository? subscriptionRepository,
  ExpenseRepository? expenseRepository,
  WalletRepository? walletRepository,
  List<Override> extraOverrides = const [],
}) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...authOverrides(
        signedInUid: signedInUid,
        repository: repository,
        userDetails: userDetails,
      ),
      ...featureOverrides(
        subscriptions: subscriptionRepository,
        expenses: expenseRepository,
        wallets: walletRepository,
      ),
      ...extraOverrides,
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PitakapApp()),
  );

  container.read(goRouterProvider).go(location);
  await tester.pumpAndSettle();

  return container;
}

Future<ProviderContainer> containerWithSubscriptions(
  SubscriptionRepository repository,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...featureOverrides(subscriptions: repository),
    ],
  );
}

/// Opens the navigation drawer from whichever branch page is on screen.
///
/// Every branch page owns its own Scaffold and attaches its own [AppDrawer],
/// so the menu button belongs to that page's AppBar rather than to the shell.
Future<void> openDrawer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu).first);
  await tester.pumpAndSettle();
}

/// Taps a destination by its label, scoped to the open drawer so labels that
/// also appear as page titles (Expenses, Stats, ...) stay unambiguous.
Future<void> tapDrawerDestination(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationDrawer),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}
