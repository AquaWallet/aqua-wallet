import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/shared/providers/current_wallet_provider.dart';
import 'package:aqua/features/wallet/wallet.dart';

/// Convenience provider that exposes the Jan3 auth state for the currently
/// active wallet. All UI should consume this instead of [jan3AuthProvider]
/// directly.
final currentWalletAuthProvider =
    NotifierProvider<CurrentWalletAuthNotifier, Jan3AuthState>(
        CurrentWalletAuthNotifier.new);

class CurrentWalletAuthNotifier extends Notifier<Jan3AuthState> {
  @override
  Jan3AuthState build() {
    final walletId = ref.watch(currentWalletIdSyncProvider);
    return ref.watch(jan3AuthProvider(walletId)).valueOrNull ??
        const Jan3AuthState.unauthenticated();
  }

  Future<void> signOut() async {
    final walletId = ref.read(currentWalletIdSyncProvider);
    await ref.read(jan3AuthProvider(walletId).notifier).signOut();
  }

  /// Signs out every stored wallet's Jan3 account.
  /// Used when switching server environments (staging ↔ production).
  Future<void> signOutAll() async {
    final wallets = ref.read(storedWalletsProvider).valueOrNull?.wallets ?? [];
    await Future.wait(
      wallets.map((w) => ref.read(jan3AuthProvider(w.id).notifier).signOut()),
    );
  }
}
