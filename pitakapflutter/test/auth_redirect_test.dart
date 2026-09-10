import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/core/router/main_shell.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/feature/auth/presentation/forgot_password/forgot_password_page.dart';
import 'package:pitakapflutter/feature/auth/presentation/login/login_page.dart';
import 'package:pitakapflutter/feature/auth/presentation/sign_up/sign_up_page.dart';

import 'helpers.dart';

void main() {
  setUpAll(registerAuthFallbacks);

  group('signed out', () {
    const protected = [
      AppRoutes.dashboard,
      AppRoutes.subscriptions,
      AppRoutes.expenses,
      AppRoutes.stats,
      AppRoutes.settings,
      AppRoutes.wallets,
      AppRoutes.history,
    ];

    testWidgets('every protected route redirects to login', (tester) async {
      for (final route in protected) {
        await pumpAppAt(tester, route);

        expect(find.byType(LoginPage), findsOneWidget, reason: route);
        expect(find.byType(MainShell), findsNothing, reason: route);
      }
    });

    testWidgets('the auth screens stay reachable', (tester) async {
      await pumpAppAt(tester, AppRoutes.login);
      expect(find.byType(LoginPage), findsOneWidget);

      await pumpAppAt(tester, AppRoutes.signUp);
      expect(find.byType(SignUpPage), findsOneWidget);

      await pumpAppAt(tester, AppRoutes.forgotPassword);
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });
  });

  group('signed in', () {
    testWidgets('protected routes render the shell', (tester) async {
      await pumpAppAt(
        tester,
        AppRoutes.subscriptions,
        signedInUid: 'uid-1',
      );

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text(Strings.subscriptionsTitle), findsWidgets);
    });

    testWidgets('the auth screens bounce to the dashboard', (tester) async {
      for (final route in [
        AppRoutes.login,
        AppRoutes.signUp,
        AppRoutes.forgotPassword,
      ]) {
        await pumpAppAt(tester, route, signedInUid: 'uid-1');

        expect(find.byType(LoginPage), findsNothing, reason: route);
        expect(find.byType(SignUpPage), findsNothing, reason: route);
        expect(find.byType(MainShell), findsOneWidget, reason: route);
      }
    });

    testWidgets('onboarding also bounces to the dashboard', (tester) async {
      await pumpAppAt(
        tester,
        AppRoutes.onboarding,
        values: const {},
        signedInUid: 'uid-1',
      );

      expect(find.byType(MainShell), findsOneWidget);
    });
  });

  group('sign out', () {
    testWidgets('the settings tab offers a sign out action', (tester) async {
      await pumpAppAt(tester, AppRoutes.settings, signedInUid: 'uid-1');

      expect(find.text(Strings.signOutAction), findsOneWidget);
    });

    testWidgets('it confirms first — one tap does not sign you out', (
      tester,
    ) async {
      final repository = MockAuthRepository();
      when(() => repository.signOut()).thenAnswer((_) async {});

      await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
        repository: repository,
      );

      await tester.tap(find.widgetWithText(ListTile, Strings.signOutAction));
      await tester.pumpAndSettle();

      expect(find.text(Strings.signOutTitle), findsOneWidget);
      verifyNever(() => repository.signOut());
    });

    testWidgets('cancelling the confirmation keeps you signed in', (
      tester,
    ) async {
      final repository = MockAuthRepository();
      when(() => repository.signOut()).thenAnswer((_) async {});

      await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
        repository: repository,
      );

      await tester.tap(find.widgetWithText(ListTile, Strings.signOutAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.cancelAction));
      await tester.pumpAndSettle();

      verifyNever(() => repository.signOut());
    });

    testWidgets('confirming calls the repository', (tester) async {
      final repository = MockAuthRepository();
      when(() => repository.signOut()).thenAnswer((_) async {});

      await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
        repository: repository,
      );

      await tester.tap(find.widgetWithText(ListTile, Strings.signOutAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, Strings.signOutAction),
      );
      await tester.pumpAndSettle();

      verify(() => repository.signOut()).called(1);
    });

    testWidgets('a failing sign out shows an error', (tester) async {
      final repository = MockAuthRepository();
      when(() => repository.signOut())
          .thenThrow(const NetworkFailure('No internet connection'));

      await pumpAppAt(
        tester,
        AppRoutes.settings,
        signedInUid: 'uid-1',
        repository: repository,
      );

      await tester.tap(find.widgetWithText(ListTile, Strings.signOutAction));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, Strings.signOutAction),
      );
      await tester.pumpAndSettle();

      expect(find.text('No internet connection'), findsOneWidget);
    });
  });

  group('sign out from the drawer', () {
    Future<MockAuthRepository> openDrawerAt(
      WidgetTester tester, {
      Object? failure,
    }) async {
      final repository = MockAuthRepository();
      if (failure == null) {
        when(() => repository.signOut()).thenAnswer((_) async {});
      } else {
        when(() => repository.signOut()).thenThrow(failure);
      }

      await pumpAppAt(
        tester,
        AppRoutes.dashboard,
        signedInUid: 'uid-1',
        repository: repository,
      );
      await openDrawer(tester);

      return repository;
    }

    testWidgets('the drawer offers a sign out button', (tester) async {
      await openDrawerAt(tester);

      expect(
        find.widgetWithText(FilledButton, Strings.signOutAction),
        findsOneWidget,
      );
    });

    testWidgets('the button carries the danger colour', (tester) async {
      await openDrawerAt(tester);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, Strings.signOutAction),
      );

      expect(
        button.style?.backgroundColor?.resolve(<WidgetState>{}),
        AppColors.danger,
      );
    });

    testWidgets('it confirms first — one tap does not sign you out', (
      tester,
    ) async {
      final repository = await openDrawerAt(tester);

      await tester.tap(
        find.widgetWithText(FilledButton, Strings.signOutAction),
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.signOutTitle), findsOneWidget);
      verifyNever(() => repository.signOut());
    });

    testWidgets('cancelling the confirmation keeps you signed in', (
      tester,
    ) async {
      final repository = await openDrawerAt(tester);

      await tester.tap(
        find.widgetWithText(FilledButton, Strings.signOutAction),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.cancelAction));
      await tester.pumpAndSettle();

      verifyNever(() => repository.signOut());
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('confirming calls the repository', (tester) async {
      final repository = await openDrawerAt(tester);

      await tester.tap(
        find.widgetWithText(FilledButton, Strings.signOutAction),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, Strings.signOutAction),
      );
      await tester.pumpAndSettle();

      verify(() => repository.signOut()).called(1);
    });

    testWidgets('a successful sign out lands you back on login', (
      tester,
    ) async {
      // The drawer deliberately does not navigate: it relies on the auth
      // stream flipping and the router's redirect doing the work.
      final auth = StreamController<String?>();
      addTearDown(auth.close);
      auth.add('uid-1');

      final repository = MockAuthRepository();
      when(() => repository.signOut()).thenAnswer((_) async {
        auth.add(null);
      });

      await pumpAppAt(
        tester,
        AppRoutes.dashboard,
        signedInUid: 'uid-1',
        authStream: auth.stream,
        repository: repository,
      );
      await openDrawer(tester);

      await tester.tap(
        find.widgetWithText(FilledButton, Strings.signOutAction),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, Strings.signOutAction),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
    });

    testWidgets('a failing sign out shows an error and stays put', (
      tester,
    ) async {
      await openDrawerAt(
        tester,
        failure: const NetworkFailure('No internet connection'),
      );

      await tester.tap(
        find.widgetWithText(FilledButton, Strings.signOutAction),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, Strings.signOutAction),
      );
      await tester.pumpAndSettle();

      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.byType(MainShell), findsOneWidget);
    });
  });
}
