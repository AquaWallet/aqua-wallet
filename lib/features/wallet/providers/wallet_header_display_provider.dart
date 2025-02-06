import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

enum WalletHeaderDisplay {
  totalBalance,
  btcPrice,
  hidden;

  WalletHeaderDisplay get next => switch (this) {
        totalBalance => btcPrice,
        btcPrice => hidden,
        hidden => totalBalance,
      };
}

class WalletHeaderDisplayNotifier extends AsyncNotifier<WalletHeaderDisplay> {
  @override
  Future<WalletHeaderDisplay> build() async {
    final showBalance = await ref.watch(showUnifiedBalanceProvider.future);
    final isBalanceHidden =
        ref.watch(prefsProvider.select((p) => p.isBalanceHidden));

    if (isBalanceHidden) {
      return WalletHeaderDisplay.hidden;
    }

    return showBalance ?? false
        ? WalletHeaderDisplay.totalBalance
        : WalletHeaderDisplay.btcPrice;
  }

  Future<void> toggle() async {
    final currentState = await future;
    final nextState = currentState.next;

    // Sync balance visibility with preferences
    if (nextState == WalletHeaderDisplay.hidden ||
        (currentState == WalletHeaderDisplay.hidden)) {
      await ref.read(prefsProvider.notifier).switchBalanceHidden();
    }

    state = AsyncData(nextState);
  }
}

final walletHeaderDisplayProvider =
    AsyncNotifierProvider<WalletHeaderDisplayNotifier, WalletHeaderDisplay>(
  WalletHeaderDisplayNotifier.new,
);
