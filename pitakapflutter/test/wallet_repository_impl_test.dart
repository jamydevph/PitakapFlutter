import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/feature/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:pitakapflutter/feature/wallet/data/model/wallet_model.dart';
import 'package:pitakapflutter/feature/wallet/data/repository/wallet_repository_impl.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/restore_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/update_wallet_usecase.dart';

class MockWalletRemoteDatasource extends Mock
    implements WalletRemoteDatasource {}

WalletModel model({String id = 'wallet-1', double openingBalance = 5000}) {
  return WalletModel(
    id: id,
    userId: 'uid-1',
    name: 'Main Wallet',
    description: 'Everyday spending',
    openingBalance: openingBalance,
  );
}

void main() {
  late MockWalletRemoteDatasource remote;
  late WalletRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const CreateWalletUseCaseParams(
        userId: '',
        name: '',
        openingBalance: 0,
      ),
    );
    registerFallbackValue(UpdateWalletUseCaseParams(model()));
    registerFallbackValue(const DeleteWalletUseCaseParams(''));
    registerFallbackValue(RestoreWalletUseCaseParams(model()));
    registerFallbackValue(
      const WalletEntity(id: '', userId: '', name: '', openingBalance: 0),
    );
  });

  setUp(() {
    remote = MockWalletRemoteDatasource();
    repository = WalletRepositoryImpl(remote);
  });

  group('watchWallets', () {
    test('passes the user through and returns the models as entities', () {
      when(
        () => remote.watchWallets(any()),
      ).thenAnswer((_) => Stream.value([model()]));

      expect(repository.watchWallets('uid-1'), emits([model()]));
      verify(() => remote.watchWallets('uid-1')).called(1);
    });

    test('lets a mapped failure reach the caller', () {
      when(() => remote.watchWallets(any())).thenAnswer(
        (_) => Stream.error(const ServerFailure('Not allowed')),
      );

      expect(
        repository.watchWallets('uid-1'),
        emitsError(isA<ServerFailure>()),
      );
    });
  });

  group('write operations delegate without reshaping', () {
    test('create swallows the new id rather than leaking it upward', () async {
      when(() => remote.createWallet(any())).thenAnswer((_) async => 'new-id');

      const params = CreateWalletUseCaseParams(
        userId: 'uid-1',
        name: 'Cash on Hand',
        openingBalance: 2000,
      );

      await repository.createWallet(params);

      verify(() => remote.createWallet(params)).called(1);
    });

    test('update', () async {
      when(() => remote.updateWallet(any())).thenAnswer((_) async {});

      final params = UpdateWalletUseCaseParams(model());

      await repository.updateWallet(params);

      verify(() => remote.updateWallet(params)).called(1);
    });

    test('delete', () async {
      when(() => remote.deleteWallet(any())).thenAnswer((_) async {});

      const params = DeleteWalletUseCaseParams('wallet-1');

      await repository.deleteWallet(params);

      verify(() => remote.deleteWallet(params)).called(1);
    });

    test('restore unwraps the entity for the datasource', () async {
      when(() => remote.restoreWallet(any())).thenAnswer((_) async {});

      final wallet = model();

      await repository.restoreWallet(RestoreWalletUseCaseParams(wallet));

      verify(() => remote.restoreWallet(wallet)).called(1);
    });

    test('a write failure propagates unchanged', () {
      when(
        () => remote.deleteWallet(any()),
      ).thenThrow(const NetworkFailure('No internet connection'));

      expect(
        () => repository.deleteWallet(const DeleteWalletUseCaseParams('x')),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
