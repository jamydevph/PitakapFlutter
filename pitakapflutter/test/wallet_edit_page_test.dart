import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/restore_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/update_wallet_usecase.dart';

import 'helpers.dart';

class RecordingWalletRepository implements WalletRepository {
  final List<WalletEntity> wallets;

  final List<CreateWalletUseCaseParams> created = [];
  final List<WalletEntity> updated = [];

  RecordingWalletRepository({this.wallets = const []});

  @override
  Stream<List<WalletEntity>> watchWallets(String userId) {
    return Stream.value(wallets);
  }

  @override
  Future<void> createWallet(CreateWalletUseCaseParams params) async {
    created.add(params);
  }

  @override
  Future<void> updateWallet(UpdateWalletUseCaseParams params) async {
    updated.add(params.wallet);
  }

  @override
  Future<void> deleteWallet(DeleteWalletUseCaseParams params) async {}

  @override
  Future<void> restoreWallet(RestoreWalletUseCaseParams params) async {}
}

void main() {
  void sizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> openAddForm(
    WidgetTester tester,
    RecordingWalletRepository repository,
  ) async {
    sizeViewport(tester);

    await pumpAppAt(
      tester,
      AppRoutes.wallets,
      signedInUid: 'uid-1',
      walletRepository: repository,
    );

    await tester.tap(find.text(Strings.walletAddAction));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String label, String value) async {
    await tester.enterText(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(TextFormField),
      ),
      value,
    );
    await tester.pumpAndSettle();
  }

  group('validation', () {
    testWidgets('an empty form refuses to save', (tester) async {
      final repository = RecordingWalletRepository();

      await openAddForm(tester, repository);

      await tester.tap(find.text(Strings.walletSaveAction));
      await tester.pumpAndSettle();

      expect(find.text(Strings.walletNameRequired), findsOneWidget);
      expect(repository.created, isEmpty);
    });

    testWidgets('a name without a balance still refuses to save', (
      tester,
    ) async {
      final repository = RecordingWalletRepository();

      await openAddForm(tester, repository);
      await fill(tester, Strings.walletNameLabel, 'Main Wallet');

      await tester.tap(find.text(Strings.walletSaveAction));
      await tester.pumpAndSettle();

      expect(repository.created, isEmpty);
    });
  });

  group('creating', () {
    testWidgets('a filled form sends every field through', (tester) async {
      final repository = RecordingWalletRepository();

      await openAddForm(tester, repository);
      await fill(tester, Strings.walletNameLabel, 'Main Wallet');
      await fill(tester, Strings.walletDescriptionLabel, 'Everyday spending');
      await fill(tester, Strings.walletOpeningBalanceLabel, '5000');

      await tester.tap(find.text(Strings.walletSaveAction));
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));

      final saved = repository.created.single;
      expect(saved.userId, 'uid-1');
      expect(saved.name, 'Main Wallet');
      expect(saved.description, 'Everyday spending');
      expect(saved.openingBalance, 5000);
    });

    testWidgets('the balance help text explains the deduction model', (
      tester,
    ) async {
      await openAddForm(tester, RecordingWalletRepository());

      expect(find.text(Strings.walletOpeningBalanceHelp), findsOneWidget);
    });
  });

  group('editing', () {
    testWidgets('opening an existing wallet prefills it', (tester) async {
      final repository = RecordingWalletRepository(
        wallets: const [
          WalletEntity(
            id: 'w1',
            userId: 'uid-1',
            name: 'Main Wallet',
            description: 'Everyday spending',
            openingBalance: 5000,
          ),
        ],
      );

      sizeViewport(tester);
      await pumpAppAt(
        tester,
        AppRoutes.wallets,
        signedInUid: 'uid-1',
        walletRepository: repository,
      );

      await tester.tap(find.text('Main Wallet'));
      await tester.pumpAndSettle();

      expect(find.text(Strings.walletEditTitle), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Main Wallet'), findsOneWidget);
    });

    testWidgets('an edit preserves id, userId and createdAt', (tester) async {
      final createdAt = DateTime(2026, 8, 1);
      final repository = RecordingWalletRepository(
        wallets: [
          WalletEntity(
            id: 'w1',
            userId: 'uid-1',
            name: 'Main Wallet',
            openingBalance: 5000,
            currency: 'PHP',
            createdAt: createdAt,
          ),
        ],
      );

      sizeViewport(tester);
      await pumpAppAt(
        tester,
        AppRoutes.wallets,
        signedInUid: 'uid-1',
        walletRepository: repository,
      );

      await tester.tap(find.text('Main Wallet'));
      await tester.pumpAndSettle();

      await fill(tester, Strings.walletNameLabel, 'Everyday Wallet');
      await tester.tap(find.text(Strings.walletSaveAction));
      await tester.pumpAndSettle();

      expect(repository.updated, hasLength(1));

      final saved = repository.updated.single;
      expect(saved.id, 'w1');
      expect(saved.userId, 'uid-1');
      expect(saved.currency, 'PHP');
      expect(saved.createdAt, createdAt);
      expect(saved.name, 'Everyday Wallet');
    });
  });
}
