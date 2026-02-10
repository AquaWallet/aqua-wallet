import 'dart:async';

import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/wallet/wallet.dart';

const kMaxWalletNameLength = 23;

final walletNameInputProvider = AutoDisposeAsyncNotifierProviderFamily<
    WalletNameInputNotifier,
    String,
    StoredWallet?>(WalletNameInputNotifier.new);

class WalletNameInputNotifier
    extends AutoDisposeFamilyAsyncNotifier<String, StoredWallet?> {
  bool _hasBeenTouched = false;

  @override
  FutureOr<String> build(StoredWallet? arg) async {
    // For existing wallets, mark as touched immediately
    _hasBeenTouched = arg != null;
    return arg?.name ?? '';
  }

  Future<void> updateText(String text) async {
    state = AsyncValue.data(text);

    // Mark as touched on first interaction
    if (!_hasBeenTouched) {
      _hasBeenTouched = true;
    }

    // Only validate after first interaction
    if (_hasBeenTouched) {
      await _validate(text);
    }
  }

  Future<void> _validate(String text) async {
    if (text.isEmpty) {
      state = AsyncValue.error(
        const WalletNameValidationException(
          WalletNameValidationExceptionType.empty,
        ),
        StackTrace.current,
      );
      return;
    }

    if (text.length > kMaxWalletNameLength) {
      state = AsyncValue.error(
        const WalletNameValidationException(
          WalletNameValidationExceptionType.tooLong,
        ),
        StackTrace.current,
      );
      return;
    }

    final walletsState = await ref.read(storedWalletsProvider.future);
    final wallets = walletsState.wallets;
    final currentWalletId = arg?.id;

    final isDuplicate = wallets.any((wallet) {
      return wallet.id != currentWalletId &&
          wallet.name.toLowerCase() == text.toLowerCase();
    });

    if (isDuplicate) {
      state = AsyncValue.error(
        const WalletNameValidationException(
          WalletNameValidationExceptionType.duplicate,
        ),
        StackTrace.current,
      );
      return;
    }

    state = AsyncValue.data(text);
  }

  Future<void> save() async {
    final text = state.valueOrNull;
    if (text == null || text.isEmpty || arg == null) {
      return;
    }

    await ref
        .read(storedWalletsProvider.notifier)
        .updateWalletName(arg!.id, text);

    ref.invalidate(storedWalletsProvider);
  }
}
