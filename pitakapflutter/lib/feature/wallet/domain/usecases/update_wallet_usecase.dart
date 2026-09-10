import 'package:pitakapflutter/core/usecase/usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';

class UpdateWalletUseCaseParams {
  final WalletEntity wallet;

  const UpdateWalletUseCaseParams(this.wallet);
}

class UpdateWalletUseCase
    implements UseCaseWithParams<void, UpdateWalletUseCaseParams> {
  final WalletRepository repository;

  const UpdateWalletUseCase(this.repository);

  @override
  Future<void> call(UpdateWalletUseCaseParams params) {
    return repository.updateWallet(params);
  }
}
