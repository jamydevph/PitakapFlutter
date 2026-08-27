import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/feature/subscription/data/datasources/reminder_local_datasource.dart';
import 'package:pitakapflutter/feature/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:pitakapflutter/feature/subscription/data/repository/subscription_repository_impl.dart';
import 'package:pitakapflutter/feature/subscription/domain/entities/subscription_entity.dart';
import 'package:pitakapflutter/feature/subscription/domain/repository/subscription_repository.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/update_subscription_usecase.dart';
import 'package:pitakapflutter/feature/subscription/domain/usecases/watch_subscriptions_usecase.dart';

final subscriptionRemoteDatasourceProvider =
    Provider<SubscriptionRemoteDatasource>(
      (ref) => SubscriptionRemoteDatasourceImpl(
        firestore: ref.watch(firestoreProvider),
      ),
    );

final localNotificationsPluginProvider = Provider<FlutterLocalNotificationsPlugin>(
  (ref) => FlutterLocalNotificationsPlugin(),
);

final reminderLocalDatasourceProvider = Provider<ReminderLocalDatasource>(
  (ref) => ReminderLocalDatasourceImpl(
    ref.watch(localNotificationsPluginProvider),
  ),
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) =>
      SubscriptionRepositoryImpl(ref.watch(subscriptionRemoteDatasourceProvider)),
);

final watchSubscriptionsUseCaseProvider = Provider<WatchSubscriptionsUseCase>(
  (ref) => WatchSubscriptionsUseCase(ref.watch(subscriptionRepositoryProvider)),
);

final createSubscriptionUseCaseProvider = Provider<CreateSubscriptionUseCase>(
  (ref) => CreateSubscriptionUseCase(ref.watch(subscriptionRepositoryProvider)),
);

final updateSubscriptionUseCaseProvider = Provider<UpdateSubscriptionUseCase>(
  (ref) => UpdateSubscriptionUseCase(ref.watch(subscriptionRepositoryProvider)),
);

final deleteSubscriptionUseCaseProvider = Provider<DeleteSubscriptionUseCase>(
  (ref) => DeleteSubscriptionUseCase(ref.watch(subscriptionRepositoryProvider)),
);

final subscriptionsStreamProvider =
    StreamProvider.family<List<SubscriptionEntity>, String>(
      (ref, userId) =>
          ref.watch(watchSubscriptionsUseCaseProvider).call(userId),
    );
