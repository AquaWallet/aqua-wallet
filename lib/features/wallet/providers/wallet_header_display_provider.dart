import 'package:riverpod_annotation/riverpod_annotation.dart';

enum WalletHeaderDisplay {
  balance,
  price;
}

class WalletHeaderDisplayNotifier extends Notifier<WalletHeaderDisplay> {
  @override
  WalletHeaderDisplay build() {
    return WalletHeaderDisplay.price;
  }

  void toggle() async {
    state = state == WalletHeaderDisplay.price
        ? WalletHeaderDisplay.balance
        : WalletHeaderDisplay.price;
  }
}

final walletHeaderDisplayProvider =
    NotifierProvider<WalletHeaderDisplayNotifier, WalletHeaderDisplay>(
  WalletHeaderDisplayNotifier.new,
);
