import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_router.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/repository/subscription_repository.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/update_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/presentation/providers/subscription_edit_controller.dart';
import 'package:pitakapflutter/feature/subscription/presentation/subscription_edit_page.dart';
import 'package:pitakapflutter/feature/subscription/presentation/subscriptions_list_page.dart';

import 'helpers.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

final netflix = SubscriptionEntity(
  id: 'sub-1',
  userId: 'uid-1',
  name: 'Netflix',
  category: 'entertainment',
  amount: 549,
  billingCycle: BillingCycle.monthly,
  firstBillDate: DateTime(2026, 1, 15),
  reminderDaysBefore: 3,
  notes: 'Family plan',
);

void main() {
  late MockSubscriptionRepository repository;

  setUpAll(() {
    registerAuthFallbacks();
    registerFallbackValue(
      CreateSubscriptionUseCaseParams(
        userId: 'uid-1',
        name: '',
        category: '',
        amount: 0,
        firstBillDate: DateTime(2026),
      ),
    );
    registerFallbackValue(UpdateSubscriptionUseCaseParams(netflix));
  });

  setUp(() {
    repository = MockSubscriptionRepository();
    when(
      () => repository.watchSubscriptions(any()),
    ).thenAnswer((_) => Stream.value([netflix]));
    when(() => repository.createSubscription(any())).thenAnswer((_) async {});
    when(() => repository.updateSubscription(any())).thenAnswer((_) async {});
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    SubscriptionEntity? existing,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpPage(
      tester,
      SubscriptionEditPage(subscription: existing),
      brightness: brightness,
      overrides: [
        ...authOverrides(signedInUid: 'uid-1'),
        ...featureOverrides(subscriptions: repository),
      ],
    );
  }

  Finder fieldWithLabel(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

  group('layout', () {
    testWidgets('add mode shows the fields above the fold', (tester) async {
      await pumpForm(tester);

      expect(find.text(Strings.subscriptionAddTitle), findsOneWidget);
      expect(find.text(Strings.subscriptionNameLabel), findsOneWidget);
      expect(find.text(Strings.subscriptionCategoryLabel), findsOneWidget);
      expect(find.text(Strings.subscriptionCycleLabel), findsOneWidget);
      expect(find.text(Strings.subscriptionSaveAction), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('scrolling reveals the date, reminder and notes', (
      tester,
    ) async {
      await pumpForm(tester);

      await tester.scrollUntilVisible(
        find.text(Strings.subscriptionNotesLabel),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.subscriptionFirstBillLabel), findsOneWidget);
      expect(find.text(Strings.subscriptionReminderLabel), findsOneWidget);
      expect(find.text(Strings.subscriptionNotesLabel), findsOneWidget);
    });

    testWidgets('offers a chip for every category and cycle', (tester) async {
      await pumpForm(tester);

      for (final category in Constants.subscriptionCategories) {
        final label = category[0].toUpperCase() + category.substring(1);
        expect(find.text(label), findsOneWidget, reason: category);
      }
      for (final cycle in BillingCycle.values) {
        expect(find.text(cycle.label), findsOneWidget, reason: cycle.name);
      }
    });

    testWidgets('offers every reminder option once scrolled', (tester) async {
      await pumpForm(tester);

      await tester.scrollUntilVisible(
        find.text(Strings.subscriptionReminderLabel),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      for (final days in SubscriptionEditPage.reminderOptions) {
        expect(
          find.text(SubscriptionEditPage.reminderLabel(days)),
          findsOneWidget,
          reason: '$days',
        );
      }
    });

    testWidgets('edit mode prefills from the subscription', (tester) async {
      await pumpForm(tester, existing: netflix);

      expect(find.text(Strings.subscriptionEditTitle), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('549.00'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(Strings.subscriptionNotesLabel),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Family plan'), findsOneWidget);
      expect(find.text('Jan 15, 2026'), findsOneWidget);
    });

    testWidgets('renders in dark mode without exceptions', (tester) async {
      await pumpForm(tester, brightness: Brightness.dark);

      expect(tester.takeException(), isNull);
    });
  });

  group('validation', () {
    testWidgets('an empty form reports the required fields', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      expect(find.text(Strings.amountRequired), findsOneWidget);
      expect(find.text(Strings.subscriptionNameRequired), findsOneWidget);
      verifyNever(() => repository.createSubscription(any()));
    });

    testWidgets('a zero amount is rejected', (tester) async {
      await pumpForm(tester);

      await tester.enterText(
        fieldWithLabel(Strings.subscriptionNameLabel),
        'Netflix',
      );
      await tester.enterText(find.byType(TextFormField).first, '0');
      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      expect(find.text(Strings.amountInvalid), findsOneWidget);
      verifyNever(() => repository.createSubscription(any()));
    });

    testWidgets('⭐ letters never reach the validator — the input formatter '
        'strips them, so the field reads as MISSING not invalid', (
      tester,
    ) async {
      await pumpForm(tester);

      await tester.enterText(
        fieldWithLabel(Strings.subscriptionNameLabel),
        'Netflix',
      );
      await tester.enterText(find.byType(TextFormField).first, 'abc');
      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      expect(find.text(Strings.amountRequired), findsOneWidget);
      expect(find.text(Strings.amountInvalid), findsNothing);
      verifyNever(() => repository.createSubscription(any()));
    });

    testWidgets('⭐ a negative amount cannot be entered at all — the formatter '
        'discards the whole value, so it reads as missing', (tester) async {
      await pumpForm(tester);

      await tester.enterText(
        fieldWithLabel(Strings.subscriptionNameLabel),
        'Netflix',
      );
      await tester.enterText(find.byType(TextFormField).first, '-100');
      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      expect(find.text(Strings.amountRequired), findsOneWidget);
      verifyNever(() => repository.createSubscription(any()));
    });

    testWidgets('⭐ more than two decimal places are truncated at input', (
      tester,
    ) async {
      await pumpForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '12.3456');
      await tester.pumpAndSettle();

      expect(find.text('12.34'), findsOneWidget);
    });

    testWidgets('⚠️ a thousands separator SILENTLY TRUNCATES — "1,500" keeps '
        'only "1", which saves as ₱1 with no warning', (tester) async {
      await pumpForm(tester);

      await tester.enterText(
        fieldWithLabel(Strings.subscriptionNameLabel),
        'Netflix',
      );
      await tester.enterText(find.byType(TextFormField).first, '1,500');
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text(Strings.amountInvalid), findsNothing);
    });

    testWidgets('⭐ a whitespace-only name counts as missing', (tester) async {
      await pumpForm(tester);

      await tester.enterText(
        fieldWithLabel(Strings.subscriptionNameLabel),
        '   ',
      );
      await tester.enterText(find.byType(TextFormField).first, '549');
      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      expect(find.text(Strings.subscriptionNameRequired), findsOneWidget);
      verifyNever(() => repository.createSubscription(any()));
    });

    testWidgets('⭐ a valid amount with a missing name still blocks the save', (
      tester,
    ) async {
      await pumpForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '549');
      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      expect(find.text(Strings.subscriptionNameRequired), findsOneWidget);
      expect(find.text(Strings.amountRequired), findsNothing);
      verifyNever(() => repository.createSubscription(any()));
    });

    testWidgets('⭐ errors persist while typing — the form validates on save, '
        'not on change, so a correction clears only on the next save', (
      tester,
    ) async {
      await pumpForm(tester);

      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      expect(find.text(Strings.subscriptionNameRequired), findsOneWidget);
      expect(find.text(Strings.amountRequired), findsOneWidget);

      await tester.enterText(
        fieldWithLabel(Strings.subscriptionNameLabel),
        'Netflix',
      );
      await tester.pumpAndSettle();

      expect(find.text(Strings.subscriptionNameRequired), findsOneWidget);

      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      expect(find.text(Strings.subscriptionNameRequired), findsNothing);
      expect(find.text(Strings.amountRequired), findsOneWidget);
    });
  });

  group('saving', () {
    Future<ProviderContainer> openForm(
      WidgetTester tester, {
      SubscriptionEntity? existing,
    }) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = await pumpAppAt(
        tester,
        AppRoutes.subscriptions,
        signedInUid: 'uid-1',
        subscriptionRepository: repository,
      );

      container
          .read(goRouterProvider)
          .push(AppRoutes.subscriptionNew, extra: existing);
      await tester.pumpAndSettle();

      return container;
    }

    testWidgets('creating sends every chosen value', (tester) async {
      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '549');
      await tester.enterText(
        fieldWithLabel(Strings.subscriptionNameLabel),
        'Netflix',
      );
      await tester.tap(find.text(BillingCycle.yearly.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () => repository.createSubscription(captureAny()),
              ).captured.single
              as CreateSubscriptionUseCaseParams;

      expect(captured.name, 'Netflix');
      expect(captured.amount, 549);
      expect(captured.userId, 'uid-1');
      expect(captured.billingCycle, BillingCycle.yearly);
    });

    testWidgets('a successful save returns to the list', (tester) async {
      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '549');
      await tester.enterText(
        fieldWithLabel(Strings.subscriptionNameLabel),
        'Netflix',
      );
      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionsListPage), findsOneWidget);
      expect(find.byType(SubscriptionEditPage), findsNothing);
      expect(find.text(Strings.subscriptionCreated), findsOneWidget);
    });

    testWidgets('editing updates rather than creating', (tester) async {
      await openForm(tester, existing: netflix);

      expect(find.text(Strings.subscriptionEditTitle), findsOneWidget);

      await tester.enterText(
        fieldWithLabel(Strings.subscriptionNameLabel),
        'Netflix Premium',
      );
      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () => repository.updateSubscription(captureAny()),
              ).captured.single
              as UpdateSubscriptionUseCaseParams;

      expect(captured.subscription.id, 'sub-1');
      expect(captured.subscription.name, 'Netflix Premium');
      expect(captured.subscription.createdAt, netflix.createdAt);
      verifyNever(() => repository.createSubscription(any()));
    });

    testWidgets('a failure is reported and the form stays open', (
      tester,
    ) async {
      when(
        () => repository.createSubscription(any()),
      ).thenThrow(const NetworkFailure('No internet connection'));

      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '549');
      await tester.enterText(
        fieldWithLabel(Strings.subscriptionNameLabel),
        'Netflix',
      );
      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pumpAndSettle();

      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.byType(SubscriptionEditPage), findsOneWidget);
    });

    testWidgets('the form locks while the request is in flight', (
      tester,
    ) async {
      final gate = Completer<void>();
      when(
        () => repository.createSubscription(any()),
      ).thenAnswer((_) => gate.future);

      await openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '549');
      await tester.enterText(
        fieldWithLabel(Strings.subscriptionNameLabel),
        'Netflix',
      );
      await tester.tap(find.text(Strings.subscriptionSaveAction));
      await tester.pump();

      final close = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.close),
          matching: find.byType(IconButton),
        ),
      );
      expect(close.onPressed, isNull);

      gate.complete();
      await tester.pumpAndSettle();

      verify(() => repository.createSubscription(any())).called(1);
    });

    test('a second save is ignored while the first is in flight', () async {
      final gate = Completer<void>();
      when(
        () => repository.createSubscription(any()),
      ).thenAnswer((_) => gate.future);

      final container = await containerWithSubscriptions(repository);
      addTearDown(container.dispose);

      final controller = container.read(
        subscriptionEditControllerProvider.notifier,
      );
      final params = CreateSubscriptionUseCaseParams(
        userId: 'uid-1',
        name: 'Netflix',
        category: 'entertainment',
        amount: 549,
        firstBillDate: DateTime(2026, 1, 15),
      );

      final first = controller.create(params);
      final second = controller.create(params);

      gate.complete();
      await Future.wait([first, second]);

      verify(() => repository.createSubscription(any())).called(1);
    });
  });

  group('reminder labels', () {
    test('read naturally for every option', () {
      expect(SubscriptionEditPage.reminderLabel(0), Strings.reminderSameDay);
      expect(SubscriptionEditPage.reminderLabel(1), Strings.reminderOneDay);
      expect(SubscriptionEditPage.reminderLabel(3), '3 days before');
    });
  });

  group('the list FAB', () {
    testWidgets('opens the add form', (tester) async {
      await pumpAppAt(
        tester,
        AppRoutes.subscriptions,
        signedInUid: 'uid-1',
        subscriptionRepository: repository,
      );

      expect(find.byType(SubscriptionsListPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionEditPage), findsOneWidget);
      expect(find.text(Strings.subscriptionAddTitle), findsOneWidget);
    });

    testWidgets('the close button returns to the list', (tester) async {
      await pumpAppAt(
        tester,
        AppRoutes.subscriptions,
        signedInUid: 'uid-1',
        subscriptionRepository: repository,
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionsListPage), findsOneWidget);
      expect(find.byType(SubscriptionEditPage), findsNothing);
    });
  });
}
