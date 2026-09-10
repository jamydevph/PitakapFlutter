import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/usecase/usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';

class CreateWalletUseCaseParams {
  final String userId;
  final String name;
  final double openingBalance;
  final String description;
  final String currency;

  const CreateWalletUseCaseParams({
    required this.userId,
    required this.name,
    required this.openingBalance,
    this.description = '',
    this.currency = Constants.defaultCurrency,
  });
}

class CreateWalletUseCase
    implements UseCaseWithParams<void, CreateWalletUseCaseParams> {
  final WalletRepository repository;

  const CreateWalletUseCase(this.repository);

  @override
  Future<void> call(CreateWalletUseCaseParams params) {
    return repository.createWallet(params);
  }
}
