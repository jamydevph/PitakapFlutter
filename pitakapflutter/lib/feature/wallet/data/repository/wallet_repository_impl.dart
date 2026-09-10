import 'package:pitakapflutter/feature/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/restore_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/update_wallet_usecase.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDatasource remote;

  const WalletRepositoryImpl(this.remote);

  @override
  Stream<List<WalletEntity>> watchWallets(String userId) {
    return remote.watchWallets(userId);
  }

  @override
  Future<void> createWallet(CreateWalletUseCaseParams params) async {
    await remote.createWallet(params);
  }

  @override
  Future<void> updateWallet(UpdateWalletUseCaseParams params) {
    return remote.updateWallet(params);
  }

  @override
  Future<void> deleteWallet(DeleteWalletUseCaseParams params) {
    return remote.deleteWallet(params);
  }

  @override
  Future<void> restoreWallet(RestoreWalletUseCaseParams params) {
    return remote.restoreWallet(params.wallet);
  }
}
