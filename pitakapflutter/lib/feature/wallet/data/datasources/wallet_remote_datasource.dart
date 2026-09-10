import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pitakapflutter/core/error/firestore_error_mapper.dart';
import 'package:pitakapflutter/core/resources/keys.dart';
import 'package:pitakapflutter/feature/wallet/data/model/wallet_model.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/update_wallet_usecase.dart';

abstract interface class WalletRemoteDatasource {
  Stream<List<WalletModel>> watchWallets(String userId);

  Future<String> createWallet(CreateWalletUseCaseParams params);

  Future<void> updateWallet(UpdateWalletUseCaseParams params);

  Future<void> deleteWallet(DeleteWalletUseCaseParams params);

  Future<void> restoreWallet(WalletEntity wallet);
}

class WalletRemoteDatasourceImpl implements WalletRemoteDatasource {
  final FirebaseFirestore firestore;

  const WalletRemoteDatasourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _collection {
    return firestore.collection(Keys.walletsCollection);
  }

  @override
  Stream<List<WalletModel>> watchWallets(String userId) {
    return _collection
        .where(Keys.userId, isEqualTo: userId)
        .snapshots()
        .map(_toSortedModels)
        .handleError((Object error) => throw FirestoreErrorMapper.from(error));
  }

  @override
  Future<String> createWallet(CreateWalletUseCaseParams params) async {
    try {
      final model = WalletModel(
        id: '',
        userId: params.userId,
        name: params.name,
        openingBalance: params.openingBalance,
        description: params.description,
        currency: params.currency,
      );

      final document = await _collection.add(model.toCreateMap());

      return document.id;
    } catch (error) {
      throw FirestoreErrorMapper.from(error);
    }
  }

  @override
  Future<void> updateWallet(UpdateWalletUseCaseParams params) async {
    try {
      final model = WalletModel.fromEntity(params.wallet);

      await _collection.doc(model.id).update(model.toUpdateMap());
    } catch (error) {
      throw FirestoreErrorMapper.from(error);
    }
  }

  @override
  Future<void> deleteWallet(DeleteWalletUseCaseParams params) async {
    try {
      await _collection.doc(params.walletId).delete();
    } catch (error) {
      throw FirestoreErrorMapper.from(error);
    }
  }

  @override
  Future<void> restoreWallet(WalletEntity wallet) async {
    try {
      final model = WalletModel.fromEntity(wallet);

      await _collection.doc(model.id).set(model.toRestoreMap());
    } catch (error) {
      throw FirestoreErrorMapper.from(error);
    }
  }

  List<WalletModel> _toSortedModels(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map(WalletModel.fromDoc).toList()..sort(_oldestFirst);
  }

  int _oldestFirst(WalletModel a, WalletModel b) {
    final left = a.createdAt;
    final right = b.createdAt;

    if (left == null && right == null) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
    if (left == null) return 1;
    if (right == null) return -1;

    return left.compareTo(right);
  }
}
