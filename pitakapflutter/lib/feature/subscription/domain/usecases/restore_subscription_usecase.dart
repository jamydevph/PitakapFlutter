import 'package:pitakapflutter/core/usecase/usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/repository/subscription_repository.dart';

class RestoreSubscriptionUseCaseParams {
  final SubscriptionEntity subscription;

  const RestoreSubscriptionUseCaseParams(this.subscription);
}

class RestoreSubscriptionUseCase
    implements UseCaseWithParams<void, RestoreSubscriptionUseCaseParams> {
  final SubscriptionRepository repository;

  const RestoreSubscriptionUseCase(this.repository);

  @override
  Future<void> call(RestoreSubscriptionUseCaseParams params) {
    return repository.restoreSubscription(params);
  }
}
