import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitakapflutter/core/error/failure.dart';
import 'package:pitakapflutter/core/providers/wallet_providers.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/domain/usecases/update_wallet_usecase.dart';
import 'package:pitakapflutter/feature/wallet/presentation/providers/wallet_edit_state.dart';

class WalletEditController extends AsyncNotifier<WalletEditState> {
  @override
  FutureOr<WalletEditState> build() => const WalletEditInitialState();

  bool get isBusy => state.value is WalletEditLoadingState;

  Future<void> create(CreateWalletUseCaseParams params) async {
    await _run(
      () => ref.read(createWalletUseCaseProvider).call(params),
      onSuccess: const WalletEditSuccessState(wasExisting: false),
    );
  }

  Future<void> updateExisting(WalletEntity wallet) async {
    await _run(
      () => ref
          .read(updateWalletUseCaseProvider)
          .call(UpdateWalletUseCaseParams(wallet)),
      onSuccess: const WalletEditSuccessState(wasExisting: true),
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required WalletEditState onSuccess,
  }) async {
    if (isBusy) return;

    state = const AsyncValue.data(WalletEditLoadingState());

    final result = await AsyncValue.guard(action);

    state = AsyncValue.data(switch (result) {
      AsyncData() => onSuccess,
      AsyncError(:final error) => WalletEditFailedState(failureMessage(error)),
      _ => const WalletEditLoadingState(),
    });
  }

  void reset() => state = const AsyncValue.data(WalletEditInitialState());
}

final walletEditControllerProvider =
    AsyncNotifierProvider.autoDispose<WalletEditController, WalletEditState>(
      WalletEditController.new,
    );
