import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/restore_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/update_subscription_usecase.dart';

abstract interface class SubscriptionRepository {
  Stream<List<SubscriptionEntity>> watchSubscriptions(String userId);

  Future<void> createSubscription(CreateSubscriptionUseCaseParams params);

  Future<void> updateSubscription(UpdateSubscriptionUseCaseParams params);

  Future<void> deleteSubscription(DeleteSubscriptionUseCaseParams params);

  Future<void> restoreSubscription(RestoreSubscriptionUseCaseParams params);

  Future<void> rescheduleAllReminders(String userId);
}
