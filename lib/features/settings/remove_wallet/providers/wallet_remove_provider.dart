import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';

final walletRemoveRequestProvider = StateNotifierProvider.autoDispose<
    RemoveWalletRequestNotifier, RemoveWalletRequestState>((ref) {
  return RemoveWalletRequestNotifier(ref);
});

class RemoveWalletRequestNotifier
    extends StateNotifier<RemoveWalletRequestState> {
  RemoveWalletRequestNotifier(this._ref)
      : super(RemoveWalletRequestState.confirm());

  final Ref _ref;

  Future<void> requestWalletRemove() async {
    final biometricAuth = await _ref.read(biometricAuthProvider.future);

    if (biometricAuth.enabled) {
      final reason = _ref.read(appLocalizationsProvider).authenticationMessage;
      final authenticated = await _ref
          .read(biometricAuthProvider.notifier)
          .authenticate(reason: reason);

      if (authenticated) {
        await _removeWallet();
      } else {
        state = RemoveWalletRequestState.verificationFailed();
      }
    } else {
      await _removeWallet();
    }
  }

  Future<void> _removeWallet() async {
    state = RemoveWalletRequestState.removing();
    await Future.wait([
      _ref.read(aquaConnectionProvider.notifier).disconnect(),
      _ref.read(secureStorageProvider).deleteAll(),
      _ref.read(sharedPreferencesProvider).clear(),
      _ref.read(transactionStorageProvider.notifier).clear(),
    ]);
    //NOTE - Verify removal
    await _ref.read(aquaConnectionProvider.notifier).connect();
    final connectionState = _ref.read(aquaConnectionProvider);
    state = connectionState.asError?.error != null
        ? RemoveWalletRequestState.success()
        : RemoveWalletRequestState.failure();
  }
}
