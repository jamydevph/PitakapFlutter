import 'package:pitakapflutter/core/usecase/usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';

class DeleteWalletUseCaseParams {
  final String walletId;

  const DeleteWalletUseCaseParams(this.walletId);
}

class DeleteWalletUseCase
    implements UseCaseWithParams<void, DeleteWalletUseCaseParams> {
  final WalletRepository repository;

  const DeleteWalletUseCase(this.repository);

  @override
  Future<void> call(DeleteWalletUseCaseParams params) {
    return repository.deleteWallet(params);
  }
}
