import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/widgets/app_logo.dart';
import 'package:pitakapflutter/feature/auth/presentation/login/login_page.dart';

import 'helpers.dart';

void main() {
  group('LoginPage layout', () {
    testWidgets('renders every element from the design', (tester) async {
      await pumpPage(tester, const LoginPage());

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text(Strings.appName), findsOneWidget);
      expect(find.text(Strings.loginTagline), findsOneWidget);
      expect(find.text(Strings.emailLabel), findsOneWidget);
      expect(find.text(Strings.passwordLabel), findsOneWidget);
      expect(find.text(Strings.loginForgotPassword), findsOneWidget);
      expect(find.text(Strings.loginSignIn), findsOneWidget);
      expect(find.text(Strings.loginOr), findsOneWidget);
      expect(find.text(Strings.loginContinueWithGoogle), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == Constants.googleLogoAsset,
        ),
        findsOneWidget,
        reason:
            'Google Sign-In branding guidelines require the official mark, '
            'not a typed letter',
      );
      expect(
        find.text('G'),
        findsNothing,
        reason: 'the placeholder letter G must never come back',
      );
      expect(
        find.textContaining(Strings.loginSignUpLink, findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(Strings.loginNoAccount, findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('renders in dark mode without overflowing', (tester) async {
      await pumpPage(
        tester,
        const LoginPage(),
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(Strings.loginSignIn), findsOneWidget);
    });
  });

  group('LoginPage validation', () {
    testWidgets('submitting an empty form surfaces both field errors', (
      tester,
    ) async {
      await pumpPage(tester, const LoginPage());

      expect(find.text(Strings.emailRequired), findsNothing);

      await tester.tap(find.text(Strings.loginSignIn));
      await tester.pumpAndSettle();

      expect(find.text(Strings.emailRequired), findsOneWidget);
      expect(find.text(Strings.passwordRequired), findsOneWidget);
    });

    testWidgets('a malformed address reports an invalid email', (tester) async {
      await pumpPage(tester, const LoginPage());

      await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
      await tester.tap(find.text(Strings.loginSignIn));
      await tester.pumpAndSettle();

      expect(find.text(Strings.emailInvalid), findsOneWidget);
    });

    testWidgets('a short password reports the minimum length', (tester) async {
      await pumpPage(tester, const LoginPage());

      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text(Strings.loginSignIn));
      await tester.pumpAndSettle();

      expect(find.text(Strings.passwordTooShort), findsOneWidget);
    });

    testWidgets('valid credentials clear every error', (tester) async {
      await pumpPage(tester, const LoginPage());

      await tester.tap(find.text(Strings.loginSignIn));
      await tester.pumpAndSettle();
      expect(find.text(Strings.emailRequired), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'diane@pitakap.app',
      );
      await tester.enterText(find.byType(TextFormField).last, 'secret123');
      await tester.tap(find.text(Strings.loginSignIn));
      await tester.pumpAndSettle();

      expect(find.text(Strings.emailRequired), findsNothing);
      expect(find.text(Strings.emailInvalid), findsNothing);
      expect(find.text(Strings.passwordRequired), findsNothing);
      expect(find.text(Strings.passwordTooShort), findsNothing);
    });
  });

  group('LoginPage password visibility', () {
    testWidgets('starts obscured and toggles on tap', (tester) async {
      await pumpPage(tester, const LoginPage());

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });
  });
}
