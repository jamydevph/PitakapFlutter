import 'package:pitakapflutter/core/usecase/usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/repository/subscription_repository.dart';

class RescheduleAllRemindersUseCase
    implements UseCaseWithParams<void, String> {
  final SubscriptionRepository repository;

  const RescheduleAllRemindersUseCase(this.repository);

  @override
  Future<void> call(String userId) {
    return repository.rescheduleAllReminders(userId);
  }
}
