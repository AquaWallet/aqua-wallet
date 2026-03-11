import 'package:aqua/features/onboarding/restore/models/models.dart';
import 'package:aqua/features/shared/shared.dart';

final walletSuccessModalProvider =
    StateNotifierProvider<WalletSuccessModalNotifier, WalletSuccessModalState>(
  (ref) => WalletSuccessModalNotifier(),
);

class WalletSuccessModalNotifier
    extends StateNotifier<WalletSuccessModalState> {
  WalletSuccessModalNotifier() : super(const WalletSuccessModalState());

  void showModal(WalletSuccessModalType type) {
    state = state.copyWith(
      modalType: type,
      hasShownModal: false,
    );
  }

  void markAsShown() {
    state = state.copyWith(hasShownModal: true);
  }

  void dismiss() {
    state = state.copyWith(
      modalType: WalletSuccessModalType.none,
      hasShownModal: false,
    );
  }

  bool get shouldShowModal =>
      state.modalType != WalletSuccessModalType.none && !state.hasShownModal;
}
