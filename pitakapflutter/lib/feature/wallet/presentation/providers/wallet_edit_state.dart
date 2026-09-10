sealed class WalletEditState {
  const WalletEditState();
}

class WalletEditInitialState extends WalletEditState {
  const WalletEditInitialState();
}

class WalletEditLoadingState extends WalletEditState {
  const WalletEditLoadingState();
}

class WalletEditSuccessState extends WalletEditState {
  final bool wasExisting;

  const WalletEditSuccessState({required this.wasExisting});
}

class WalletEditFailedState extends WalletEditState {
  final String message;

  const WalletEditFailedState(this.message);
}
