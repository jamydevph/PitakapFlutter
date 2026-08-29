import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/feature/subscription/data/datasources/reminder_local_datasource.dart';
import 'package:pitakapflutter/feature/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/reminder_schedule.dart';
import 'package:pitakapflutter/feature/subscription/domain/repository/subscription_repository.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/restore_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/update_subscription_usecase.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDatasource remote;
  final ReminderLocalDatasource reminders;
  final DateTime Function() clock;

  SubscriptionRepositoryImpl(
    this.remote,
    this.reminders, {
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  @override
  Stream<List<SubscriptionEntity>> watchSubscriptions(String userId) {
    return remote.watchSubscriptions(userId);
  }

  @override
  Future<void> createSubscription(CreateSubscriptionUseCaseParams params) async {
    final id = await remote.createSubscription(params);

    await _withoutFailingTheWrite(() => _syncReminder(_entityFrom(params, id)));
  }

  @override
  Future<void> updateSubscription(UpdateSubscriptionUseCaseParams params) async {
    await remote.updateSubscription(params);

    await _withoutFailingTheWrite(() => _syncReminder(params.subscription));
  }

  @override
  Future<void> deleteSubscription(DeleteSubscriptionUseCaseParams params) async {
    await remote.deleteSubscription(params);

    await _withoutFailingTheWrite(
      () => reminders.cancelReminder(reminderIdFor(params.subscriptionId)),
    );
  }

  @override
  Future<void> restoreSubscription(
    RestoreSubscriptionUseCaseParams params,
  ) async {
    await remote.restoreSubscription(params.subscription);

    await _withoutFailingTheWrite(() => _syncReminder(params.subscription));
  }

  @override
  Future<void> rescheduleAllReminders(String userId) async {
    final subscriptions = await remote.watchSubscriptions(userId).first;

    await _withoutFailingTheWrite(() async {
      await reminders.cancelAll();

      for (final subscription in subscriptions) {
        await _syncReminder(subscription);
      }
    });
  }

  Future<void> _syncReminder(SubscriptionEntity subscription) async {
    final reminder = reminderFor(subscription, now: clock());

    if (reminder == null) {
      await reminders.cancelReminder(reminderIdFor(subscription.id));
      return;
    }

    await reminders.scheduleReminder(
      id: reminder.id,
      title: Strings.reminderTitle,
      body: reminderBodyFor(
        name: subscription.name,
        daysBefore: subscription.reminderDaysBefore,
      ),
      fireAt: reminder.fireAt,
      payload: subscription.id,
    );
  }

  Future<void> _withoutFailingTheWrite(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      return;
    }
  }

  SubscriptionEntity _entityFrom(
    CreateSubscriptionUseCaseParams params,
    String id,
  ) {
    return SubscriptionEntity(
      id: id,
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
  }
}
