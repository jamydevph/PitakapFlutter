import 'package:pitakapflutter/core/usecase/usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';

class RestoreWalletUseCaseParams {
  final WalletEntity wallet;

  const RestoreWalletUseCaseParams(this.wallet);
}

class RestoreWalletUseCase
    implements UseCaseWithParams<void, RestoreWalletUseCaseParams> {
  final WalletRepository repository;

  const RestoreWalletUseCase(this.repository);

  @override
  Future<void> call(RestoreWalletUseCaseParams params) {
    return repository.restoreWallet(params);
  }
}
