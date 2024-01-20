import 'package:freezed_annotation/freezed_annotation.dart';

part 'remove_wallet_state.freezed.dart';

@freezed
class RemoveWalletRequestState with _$RemoveWalletRequestState {
  factory RemoveWalletRequestState.verificationFailed() = _VerificationFailed;
  factory RemoveWalletRequestState.confirm() = _Confirm;
  factory RemoveWalletRequestState.removing() = _Removing;
  factory RemoveWalletRequestState.success() = _Success;
  factory RemoveWalletRequestState.failure() = _Failure;
}
