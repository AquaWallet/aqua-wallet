import 'package:aqua/features/wallet/models/stored_wallet.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_state.freezed.dart';

enum WalletOperationType {
  create,
  restore,
}

@freezed
class WalletState with _$WalletState {
  const factory WalletState({
    required List<StoredWallet> wallets,
    StoredWallet? currentWallet,
    WalletOperationType? lastOperationType,
  }) = _WalletState;

  factory WalletState.initial() => const WalletState(wallets: []);
}
