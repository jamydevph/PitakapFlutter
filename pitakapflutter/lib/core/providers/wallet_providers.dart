import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/feature/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:pitakapflutter/feature/wallet/data/repository/wallet_repository_impl.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/repository/wallet_repository.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/restore_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/update_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/watch_wallets_usecase.dart';

final walletRemoteDatasourceProvider = Provider<WalletRemoteDatasource>(
  (ref) => WalletRemoteDatasourceImpl(firestore: ref.watch(firestoreProvider)),
);

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepositoryImpl(ref.watch(walletRemoteDatasourceProvider)),
);

final watchWalletsUseCaseProvider = Provider<WatchWalletsUseCase>(
  (ref) => WatchWalletsUseCase(ref.watch(walletRepositoryProvider)),
);

final createWalletUseCaseProvider = Provider<CreateWalletUseCase>(
  (ref) => CreateWalletUseCase(ref.watch(walletRepositoryProvider)),
);

final updateWalletUseCaseProvider = Provider<UpdateWalletUseCase>(
  (ref) => UpdateWalletUseCase(ref.watch(walletRepositoryProvider)),
);

final deleteWalletUseCaseProvider = Provider<DeleteWalletUseCase>(
  (ref) => DeleteWalletUseCase(ref.watch(walletRepositoryProvider)),
);

final restoreWalletUseCaseProvider = Provider<RestoreWalletUseCase>(
  (ref) => RestoreWalletUseCase(ref.watch(walletRepositoryProvider)),
);

final walletsStreamProvider = StreamProvider.family<List<WalletEntity>, String>(
  (ref, userId) => ref.watch(watchWalletsUseCaseProvider).call(userId),
);
