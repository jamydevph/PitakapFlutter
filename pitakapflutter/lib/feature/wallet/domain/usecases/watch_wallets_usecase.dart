import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';

class WatchWalletsUseCase {
  final WalletRepository repository;

  const WatchWalletsUseCase(this.repository);

  Stream<List<WalletEntity>> call(String userId) {
    return repository.watchWallets(userId);
  }
}
