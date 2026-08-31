import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/settings_providers.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/keys.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/feature/profile/presentation/settings_page.dart';

import 'helpers.dart';

void main() {
  setUpAll(registerAuthFallbacks);

  void sizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('labels', () {
    test('⭐ a same-day reminder never reads "0 days before"', () {
      expect(reminderDaysLabel(0), Strings.reminderSameDay);
      expect(reminderDaysLabel(-1), Strings.reminderSameDay);
    });

    test('⭐ one day reads as "1 day before", not "1 days"', () {
      expect(reminderDaysLabel(1), Strings.reminderOneDay);
    });

    test('several days reads plainly', () {
      expect(reminderDaysLabel(7), '7 days before');
    });

    test('the currency label carries the code and the symbol', () {
      expect(currencyLabel('PHP'), contains('PHP'));
      expect(currencyLabel('PHP'), contains('₱'));
    });

    test('every theme mode has a label', () {
      for (final mode in ThemeMode.values) {
        expect(themeModeLabel(mode), isNotEmpty, reason: mode.name);
      }
    });
  });

  group('DefaultCurrencyController', () {
    test('falls back to the app default when nothing is stored', () async {
      final container = await containerWith(onboarded);
      addTearDown(container.dispose);

      expect(container.read(defaultCurrencyProvider), Constants.defaultCurrency);
    });

    test('reads a stored currency', () async {
      final container = await containerWith({
        ...onboarded,
        Keys.prefsDefaultCurrency: 'USD',
      });
      addTearDown(container.dispose);

      expect(container.read(defaultCurrencyProvider), 'USD');
    });

    test('⭐ an unknown stored code falls back instead of being trusted', () async {
      final container = await containerWith({
        ...onboarded,
        Keys.prefsDefaultCurrency: 'XYZ',
      });
      addTearDown(container.dispose);

      expect(container.read(defaultCurrencyProvider), Constants.defaultCurrency);
    });

    test('⭐ a selection persists to shared preferences', () async {
      final container = await containerWith(onboarded);
      addTearDown(container.dispose);

      await container.read(defaultCurrencyProvider.notifier).setCurrency('JPY');

      expect(container.read(defaultCurrencyProvider), 'JPY');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(Keys.prefsDefaultCurrency), 'JPY');
    });

    test('⭐ an unsupported code is rejected, not written', () async {
      final container = await containerWith(onboarded);
      addTearDown(container.dispose);

      await container.read(defaultCurrencyProvider.notifier).setCurrency('XYZ');

      expect(container.read(defaultCurrencyProvider), Constants.defaultCurrency);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(Keys.prefsDefaultCurrency), isNull);
    });
  });

  group('DefaultReminderDaysController', () {
    test('falls back to the app default when nothing is stored', () async {
      final container = await containerWith(onboarded);
      addTearDown(container.dispose);

      expect(
        container.read(defaultReminderDaysProvider),
        Constants.defaultReminderDaysBefore,
      );
    });

    test('⭐ zero is a real stored value, not "unset"', () async {
      final container = await containerWith({
        ...onboarded,
        Keys.prefsDefaultReminderDays: 0,
      });
      addTearDown(container.dispose);

      expect(container.read(defaultReminderDaysProvider), 0);
    });

    test('⭐ a value outside the offered options falls back', () async {
      final container = await containerWith({
        ...onboarded,
        Keys.prefsDefaultReminderDays: 99,
      });
      addTearDown(container.dispose);

      expect(
        container.read(defaultReminderDaysProvider),
        Constants.defaultReminderDaysBefore,
      );
    });

    test('a selection persists to shared preferences', () async {
      final container = await containerWith(onboarded);
      addTearDown(container.dispose);

      await container.read(defaultReminderDaysProvider.notifier).setDays(7);

      expect(container.read(defaultReminderDaysProvider), 7);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(Keys.prefsDefaultReminderDays), 7);
    });
  });

  group('SettingsPage', () {
    testWidgets('shows the signed-in profile', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(tester, AppRoutes.settings, signedInUid: 'uid-1');

      expect(find.text('Diane Magno'), findsOneWidget);
      expect(find.text('diane@pitakap.app'), findsOneWidget);
      expect(find.text('DM'), findsOneWidget);
    });

    testWidgets('survives a missing userDetails document', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
        userDetails: null,
      );

      expect(find.text('Diane Magno'), findsNothing);
      expect(find.text(Strings.settingsTitle), findsWidgets);
    });

    testWidgets('shows the three preference rows with their values', (
      tester,
    ) async {
      sizeViewport(tester);

      await pumpAppAt(tester, AppRoutes.settings, signedInUid: 'uid-1');

      expect(find.text(Strings.settingsCurrencyLabel), findsOneWidget);
      expect(find.text(Strings.settingsReminderLabel), findsOneWidget);
      expect(find.text(Strings.settingsThemeLabel), findsOneWidget);

      expect(find.text(currencyLabel(Constants.defaultCurrency)), findsOneWidget);
      expect(
        find.text(reminderDaysLabel(Constants.defaultReminderDaysBefore)),
        findsOneWidget,
      );
    });

    testWidgets('⭐ picking a currency persists it and updates the row', (
      tester,
    ) async {
      sizeViewport(tester);

      final container = await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
      );

      await tester.tap(
        find.widgetWithText(ListTile, Strings.settingsCurrencyLabel),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(currencyLabel('USD')));
      await tester.pumpAndSettle();

      expect(container.read(defaultCurrencyProvider), 'USD');
      expect(find.text(currencyLabel('USD')), findsOneWidget);
    });

    testWidgets('⭐ picking a reminder lead time persists it', (tester) async {
      sizeViewport(tester);

      final container = await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
      );

      await tester.tap(
        find.widgetWithText(ListTile, Strings.settingsReminderLabel),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(reminderDaysLabel(7)));
      await tester.pumpAndSettle();

      expect(container.read(defaultReminderDaysProvider), 7);
    });

    testWidgets('⭐ picking a theme mode persists it', (tester) async {
      sizeViewport(tester);

      final container = await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
      );

      await tester.tap(
        find.widgetWithText(ListTile, Strings.settingsThemeLabel),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(Strings.settingsThemeDark));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    testWidgets('shows the app version', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(tester, AppRoutes.settings, signedInUid: 'uid-1');

      expect(
        find.text('${Strings.settingsVersionLabel} ${Constants.appVersion}'),
        findsOneWidget,
      );
    });
  });

  group('delete account', () {
    testWidgets('⭐ it confirms first — one tap does not delete', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = MockAuthRepository();
      when(() => repository.deleteAccount()).thenAnswer((_) async {});

      await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
        repository: repository,
      );

      await tester.tap(
        find.widgetWithText(ListTile, Strings.deleteAccountAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.deleteAccountTitle), findsOneWidget);
      verifyNever(() => repository.deleteAccount());
    });

    testWidgets('⭐ the warning says the data goes too', (tester) async {
      sizeViewport(tester);

      await pumpAppAt(tester, AppRoutes.settings, signedInUid: 'uid-1');

      await tester.tap(
        find.widgetWithText(ListTile, Strings.deleteAccountAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.deleteAccountMessage), findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsOneWidget);
    });

    testWidgets('cancelling keeps the account', (tester) async {
      sizeViewport(tester);

      final repository = MockAuthRepository();
      when(() => repository.deleteAccount()).thenAnswer((_) async {});

      await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
        repository: repository,
      );

      await tester.tap(
        find.widgetWithText(ListTile, Strings.deleteAccountAction),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.cancelAction));
      await tester.pumpAndSettle();

      verifyNever(() => repository.deleteAccount());
    });

    testWidgets('confirming calls the repository', (tester) async {
      sizeViewport(tester);

      final repository = MockAuthRepository();
      when(() => repository.deleteAccount()).thenAnswer((_) async {});

      await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
        repository: repository,
      );

      await tester.tap(
        find.widgetWithText(ListTile, Strings.deleteAccountAction),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, Strings.deleteAction));
      await tester.pumpAndSettle();

      verify(() => repository.deleteAccount()).called(1);
    });

    testWidgets('⭐ a stale-login failure surfaces its mapped message', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = MockAuthRepository();
      when(() => repository.deleteAccount()).thenThrow(
        const ServerFailure('Please sign in again to continue'),
      );

      await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
        repository: repository,
      );

      await tester.tap(
        find.widgetWithText(ListTile, Strings.deleteAccountAction),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, Strings.deleteAction));
      await tester.pumpAndSettle();

      expect(find.text('Please sign in again to continue'), findsOneWidget);
    });

    testWidgets('⭐ a raw error never leaks its internals', (tester) async {
      sizeViewport(tester);

      final repository = MockAuthRepository();
      when(
        () => repository.deleteAccount(),
      ).thenThrow(StateError('internal detail'));

      await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
        repository: repository,
      );

      await tester.tap(
        find.widgetWithText(ListTile, Strings.deleteAccountAction),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, Strings.deleteAction));
      await tester.pumpAndSettle();

      expect(find.textContaining('internal detail'), findsNothing);
      expect(find.text(Strings.genericError), findsOneWidget);
    });
  });
}
