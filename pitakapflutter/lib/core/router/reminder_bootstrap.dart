import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitakapflutter/core/providers/auth_providers.dart';
import 'package:pitakapflutter/core/providers/subscription_providers.dart';
import 'package:pitakapflutter/core/router/app_router.dart';
import 'package:pitakapflutter/core/router/app_routes.dart';
import 'package:pitakapflutter/feature/subscription/data/datasources/reminder_local_datasource.dart';

class ReminderBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const ReminderBootstrap({required this.child, super.key});

  @override
  ConsumerState<ReminderBootstrap> createState() => _ReminderBootstrapState();
}

class _ReminderBootstrapState extends ConsumerState<ReminderBootstrap> {
  late final ReminderLocalDatasource _reminders;

  String? _rescheduledFor;

  @override
  void initState() {
    super.initState();

    _reminders = ref.read(reminderLocalDatasourceProvider)
      ..onReminderTap = _openSubscription;
  }

  @override
  void dispose() {
    _reminders.onReminderTap = null;

    super.dispose();
  }

  void _openSubscription(String subscriptionId) {
    if (subscriptionId.isEmpty) return;

    ref
        .read(goRouterProvider)
        .push(AppRoutes.subscriptionDetailPath(subscriptionId));
  }

  Future<void> _reschedule(String userId) async {
    if (_rescheduledFor == userId) return;

    _rescheduledFor = userId;

    try {
      await ref.read(rescheduleAllRemindersUseCaseProvider).call(userId);
    } catch (_) {
      return;
    }
  }

  Future<void> _clear() async {
    _rescheduledFor = null;

    try {
      await _reminders.cancelAll();
    } catch (_) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      final userId = next.value;

      if (userId == null) {
        _clear();
        return;
      }

      _reschedule(userId);
    });

    return widget.child;
  }
}
