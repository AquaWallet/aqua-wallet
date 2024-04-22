import 'dart:async';

import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/secure_storage_provider.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';

const kMnemonicLength = 12;

// Indicates wether all input fields have been filled. Used toggle the restore
// button state.

final walletRestoreInputCompleteProvider = Provider.autoDispose<bool>((ref) {
  return List.generate(
    kMnemonicLength,
    (index) => ref.watch(mnemonicWordInputStateProvider(index)),
  ).every((value) => value.text.isNotEmpty);
});

// Manages the actual operation of restoring a wallet from mnemonic input.

final walletRestoreProvider =
    AsyncNotifierProvider<WalletRestoreNotifier, void>(
        WalletRestoreNotifier.new);

class WalletRestoreNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async => null;

  Future<void> restore() async {
    state = const AsyncValue.loading();
    final mnemonic = List.generate(
      kMnemonicLength,
      (i) => ref.read(mnemonicWordInputStateProvider(i)).text.toLowerCase(),
    );
    final isValid = await ref.read(liquidProvider).validateMnemonic(mnemonic);
    if (isValid) {
      ref.read(backupReminderProvider).setIsWalletBackedUp(true);
      await ref
          .read(secureStorageProvider)
          .save(key: StorageKeys.mnemonic, value: mnemonic.join(' '));
    } else {
      final error = WalletRestoreInvalidMnemonicException();
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }

    await ref.read(aquaConnectionProvider.notifier).connect();
    state = const AsyncValue.data(null);
  }
}
