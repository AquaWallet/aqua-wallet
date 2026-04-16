import 'package:aqua/features/wallet/wallet.dart';

/// Asynchronously gets the current wallet ID, ensuring the wallet state is loaded.
/// Throws an exception if no wallet is available.
final currentWalletIdOrThrowProvider =
    FutureProvider.autoDispose<String>((ref) async {
  final walletState = await ref.read(storedWalletsProvider.future);
  final walletId = walletState.currentWallet?.id;
  if (walletId == null) {
    throw Exception('No wallet available');
  }
  return walletId;
});

/// Synchronously returns the current wallet ID.
/// Returns an empty string if no wallet is loaded yet.
/// Use this to pass a wallet ID to family providers.
final currentWalletIdSyncProvider = Provider<String>((ref) {
  return ref.watch(storedWalletsProvider).valueOrNull?.currentWallet?.id ?? '';
});

final currentWalletProvider =
    NotifierProvider.autoDispose<CurrentWalletNotifier, StoredWallet?>(
        CurrentWalletNotifier.new);

class CurrentWalletNotifier extends AutoDisposeNotifier<StoredWallet?> {
  @override
  StoredWallet? build() {
    final walletState = ref.watch(storedWalletsProvider);
    // Extract the ID from the currentWallet within the loaded state
    // Return null if state is loading/error or no wallet is current
    return walletState.asData?.value.currentWallet;
  }
}
