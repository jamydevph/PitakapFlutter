import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/restore_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/update_wallet_usecase.dart';

abstract interface class WalletRepository {
  Stream<List<WalletEntity>> watchWallets(String userId);

  Future<void> createWallet(CreateWalletUseCaseParams params);

  Future<void> updateWallet(UpdateWalletUseCaseParams params);

  Future<void> deleteWallet(DeleteWalletUseCaseParams params);

  Future<void> restoreWallet(RestoreWalletUseCaseParams params);
}
