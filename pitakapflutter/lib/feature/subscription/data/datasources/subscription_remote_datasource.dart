import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pitakapflutter/core/error/firestore_error_mapper.dart';
import 'package:pitakapflutter/core/resources/keys.dart';
import 'package:pitakapflutter/feature/subscription/data/model/subscription_model.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/update_subscription_usecase.dart';

abstract interface class SubscriptionRemoteDatasource {
  Stream<List<SubscriptionModel>> watchSubscriptions(String userId);

  Future<String> createSubscription(CreateSubscriptionUseCaseParams params);

  Future<void> updateSubscription(UpdateSubscriptionUseCaseParams params);

  Future<void> deleteSubscription(DeleteSubscriptionUseCaseParams params);

  Future<void> restoreSubscription(SubscriptionEntity subscription);
}

class SubscriptionRemoteDatasourceImpl implements SubscriptionRemoteDatasource {
  final FirebaseFirestore firestore;

  const SubscriptionRemoteDatasourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _collection {
    return firestore.collection(Keys.subscriptionsCollection);
  }

  @override
  Stream<List<SubscriptionModel>> watchSubscriptions(String userId) {
    return _collection
        .where(Keys.userId, isEqualTo: userId)
        .snapshots()
        .map(_toSortedModels)
        .handleError((Object error) => throw FirestoreErrorMapper.from(error));
  }

  @override
  Future<String> createSubscription(
    CreateSubscriptionUseCaseParams params,
  ) async {
    try {
      final model = SubscriptionModel(
        id: '',
        userId: params.userId,
        name: params.name,
        category: params.category,
        amount: params.amount,
        currency: params.currency,
        billingCycle: params.billingCycle,
        firstBillDate: params.firstBillDate,
        reminderDaysBefore: params.reminderDaysBefore,
        colorHex: params.colorHex,
        iconKey: params.iconKey,
        notes: params.notes,
        isActive: params.isActive,
      );

      final document = await _collection.add(model.toCreateMap());

      return document.id;
    } catch (error) {
      throw FirestoreErrorMapper.from(error);
    }
  }

  @override
  Future<void> restoreSubscription(SubscriptionEntity subscription) async {
    try {
      final model = SubscriptionModel.fromEntity(subscription);

      await _collection.doc(model.id).set(model.toRestoreMap());
    } catch (error) {
      throw FirestoreErrorMapper.from(error);
    }
  }

  @override
  Future<void> updateSubscription(UpdateSubscriptionUseCaseParams params) async {
    try {
      final model = SubscriptionModel.fromEntity(params.subscription);

      await _collection.doc(model.id).update(model.toUpdateMap());
    } catch (error) {
      throw FirestoreErrorMapper.from(error);
    }
  }

  @override
  Future<void> deleteSubscription(DeleteSubscriptionUseCaseParams params) async {
    try {
      await _collection.doc(params.subscriptionId).delete();
    } catch (error) {
      throw FirestoreErrorMapper.from(error);
    }
  }

  List<SubscriptionModel> _toSortedModels(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map(SubscriptionModel.fromDoc).toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
  }
}
