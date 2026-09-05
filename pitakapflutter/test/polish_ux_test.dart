import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pitakapflutter/core/common/common.dart';
import 'package:pitakapflutter/core/resources/billing_cycle.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/repository/subscription_repository.dart';
import 'package:pitakapflutter/feature/subscription/presentation/widgets/subscription_tile.dart';

import 'helpers.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

SubscriptionEntity sub({required String id, required String name}) {
  return SubscriptionEntity(
    id: id,
    userId: 'uid-1',
    name: name,
    category: 'entertainment',
    amount: 549,
    billingCycle: BillingCycle.monthly,
    firstBillDate: DateTime(2026, 1, 15),
  );
}

void main() {
  setUpAll(registerAuthFallbacks);

  void sizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('subscriptionAvatarTag', () {
    test('is stable for the same id', () {
      expect(subscriptionAvatarTag('sub-1'), subscriptionAvatarTag('sub-1'));
    });

    test('differs per subscription, so two tiles never share a Hero tag', () {
      expect(
        subscriptionAvatarTag('sub-1'),
        isNot(subscriptionAvatarTag('sub-2')),
      );
    });

    test('an empty id still produces a usable tag', () {
      expect(subscriptionAvatarTag(''), isNotEmpty);
    });
  });

  group('CommonListEntrance', () {
    test('the stagger is capped, so item 500 is not half a minute late', () {
      expect(
        CommonListEntrance.durationFor(500),
        CommonListEntrance.durationFor(CommonListEntrance.maxStaggeredItems),
      );
    });

    test('the first item uses the base duration with no delay', () {
      expect(
        CommonListEntrance.durationFor(0),
        CommonListEntrance.baseDuration,
      );
    });

    test('a later item takes longer than an earlier one, up to the cap', () {
      expect(
        CommonListEntrance.durationFor(3) >
            CommonListEntrance.durationFor(0),
        isTrue,
      );
    });

    test('a negative index cannot produce a duration shorter than the base', () {
      expect(
        CommonListEntrance.durationFor(-5),
        CommonListEntrance.baseDuration,
      );
    });

    test('the whole stagger stays under a second', () {
      expect(
        CommonListEntrance.durationFor(CommonListEntrance.maxStaggeredItems),
        lessThan(const Duration(seconds: 1)),
      );
    });

    testWidgets('settles fully visible and does not leave a pending timer', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CommonListEntrance(index: 2, child: Text('Netflix')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Netflix'), findsOneWidget);
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    });
  });

  group('subscriptions list polish', () {
    testWidgets('every tile carries a Hero for the shared-element push', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = MockSubscriptionRepository();
      when(() => repository.watchSubscriptions(any())).thenAnswer(
        (_) => Stream.value([
          sub(id: 'a', name: 'Netflix'),
          sub(id: 'b', name: 'Spotify'),
        ]),
      );

      await pumpAppAt(
        tester,
        AppRoutes.subscriptions,
        signedInUid: 'uid-1',
        subscriptionRepository: repository,
      );

      Finder heroWithTag(String id) => find.byWidgetPredicate(
        (widget) =>
            widget is Hero && widget.tag == subscriptionAvatarTag(id),
      );

      expect(heroWithTag('a'), findsOneWidget);
      expect(heroWithTag('b'), findsOneWidget);
      expect(heroWithTag('missing'), findsNothing);
    });

    testWidgets('the list still renders every tile with the entrance wrapper', (
      tester,
    ) async {
      sizeViewport(tester);

      final repository = MockSubscriptionRepository();
      when(() => repository.watchSubscriptions(any())).thenAnswer(
        (_) => Stream.value([
          sub(id: 'a', name: 'Netflix'),
          sub(id: 'b', name: 'Spotify'),
          sub(id: 'c', name: 'iCloud'),
        ]),
      );

      await pumpAppAt(
        tester,
        AppRoutes.subscriptions,
        signedInUid: 'uid-1',
        subscriptionRepository: repository,
      );

      expect(find.byType(CommonListEntrance), findsNWidgets(3));
      expect(find.byType(SubscriptionTile), findsNWidgets(3));
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('iCloud'), findsOneWidget);
    });
  });
}

