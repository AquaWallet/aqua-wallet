import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/utils/bip32_utils.dart';
import 'package:aqua/features/wallet/wallet.dart';

const kMnemonicLength = 12;

// Indicates wether all input fields have been filled. Used toggle the restore
// button state.

final walletRestoreInputCompleteProvider = Provider.autoDispose<bool>((ref) {
  final options = ref.watch(walletHintWordListProvider).valueOrNull ?? [];
  return List.generate(
    kMnemonicLength,
    (index) => ref.watch(mnemonicWordInputStateProvider(index)),
  ).every((value) {
    final isExactMatch = options.contains(value.text.toLowerCase());
    return value.text.isNotEmpty && isExactMatch;
  });
});

// Manages the actual operation of restoring a wallet from mnemonic input.

final walletRestoreProvider =
    AsyncNotifierProvider<WalletRestoreNotifier, bool>(
        WalletRestoreNotifier.new);

class WalletRestoreNotifier extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() async => false;

  Future<void> restore(String seedPhrase, {String? walletName}) async {
    state = await AsyncValue.guard(() async {
      final isValid = await ref
          .read(liquidProvider)
          .validateMnemonic(seedPhrase.split(' '));

      if (isValid) {
        // NOTE - No need to remind for backup since we're restoring
        ref.read(backupReminderProvider).setIsWalletBackedUp(true);

        final wallets =
            ref.read(storedWalletsProvider).valueOrNull?.wallets ?? [];
        final walletId = generateBip32Fingerprint(seedPhrase);
        final existingWallet =
            wallets.firstWhereOrNull((w) => w.id == walletId);

        if (existingWallet != null) {
          throw WalletRestoreWalletAlreadyExistsException();
        } else if (walletName != null) {
          await ref.read(storedWalletsProvider.notifier).addWallet(
                mnemonic: seedPhrase,
                name: walletName,
                operationType: WalletOperationType.restore,
              );
        } else {
          await ref.read(aquaConnectionProvider.notifier).connect();
        }

        return false;
      } else {
        throw WalletRestoreInvalidMnemonicException();
      }
    });
  }

  Future<void> restoreValidatedMnemonic(String seedPhrase,
      {String? walletName}) async {
    state = await AsyncValue.guard(() async {
      // No need to remind for backup since we're restoring
      ref.read(backupReminderProvider).setIsWalletBackedUp(true);

      // Add to stored wallets if name is provided
      if (walletName != null) {
        await ref.read(storedWalletsProvider.notifier).addWallet(
              mnemonic: seedPhrase,
              name: walletName,
              operationType: WalletOperationType.restore,
            );
      }

      await ref.read(aquaConnectionProvider.notifier).connect();
      return false;
    });
  }

  Future<void> validateMnemonicAndGetWalletInfo() async {
    state = const AsyncValue.loading();

    // Collect mnemonic from input fields
    final mnemonic = List.generate(
      kMnemonicLength,
      (i) => ref.read(mnemonicWordInputStateProvider(i)).text.toLowerCase(),
    ).join(' ');

    // Validate mnemonic first
    final isValid =
        await ref.read(liquidProvider).validateMnemonic(mnemonic.split(' '));

    if (!isValid) {
      state = AsyncValue.error(
          WalletRestoreInvalidMnemonicException(), StackTrace.current);
      return;
    }

    // Handle wallet names for multi-wallet
    // Check if wallet already exists
    final wallets = ref.read(storedWalletsProvider).valueOrNull?.wallets ?? [];
    final walletId = generateBip32Fingerprint(mnemonic);
    final existingWallet = wallets.firstWhereOrNull((w) => w.id == walletId);

    if (existingWallet != null) {
      state = AsyncValue.error(
          WalletRestoreWalletAlreadyExistsException(), StackTrace.current);
    } else {
      // Need to prompt for wallet name - set flag for UI to handle navigation
      state = const AsyncValue.data(true);
    }
  }

  Future<void> handleWalletNameInput(String mnemonic, String walletName) async {
    state = await AsyncValue.guard(() async {
      await restoreValidatedMnemonic(mnemonic, walletName: walletName);
      return false;
    });
  }
}
