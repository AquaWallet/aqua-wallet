import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_success_modal_state.freezed.dart';

enum WalletSuccessModalType {
  none,
  created,
  restored,
  deleted,
}

@freezed
class WalletSuccessModalState with _$WalletSuccessModalState {
  const factory WalletSuccessModalState({
    @Default(WalletSuccessModalType.none) WalletSuccessModalType modalType,
    @Default(false) bool hasShownModal,
  }) = _WalletSuccessModalState;
}
