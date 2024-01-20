import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/secure_storage_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/aqua_ext.dart';

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
    await _removeWallet();
  }

  Future<void> _removeWallet() async {
    state = RemoveWalletRequestState.removing();
    await Future.wait([
      _ref.read(aquaProvider).disconnect(),
      _ref.read(secureStorageProvider).deleteAll(),
      _ref.read(sharedPreferencesProvider).clear()
    ]);
    //NOTE - Verify removal
    _ref.read(aquaProvider).authorize();
    state = await _ref.readAquaBool((p) => p.authStream.first)
        ? RemoveWalletRequestState.success()
        : RemoveWalletRequestState.failure();
  }
}
