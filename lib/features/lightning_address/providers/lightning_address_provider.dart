import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/feature_flags/providers/setup_config_provider.dart';
import 'package:aqua/features/lightning_address/models/lightning_address_models.dart';
import 'package:aqua/features/shared/shared.dart';

/// Returns the user's lightning address and toggle state when authenticated,
/// the remote feature flag is enabled, and the account is bound to this wallet.
final lightningAddressProvider =
    Provider.autoDispose<LightningAddressState?>((ref) {
  final isEnabled = ref.watch(lnAddressRemoteFlagProvider);
  if (!isEnabled) return null;

  final walletId = ref.watch(currentWalletIdSyncProvider);
  final profile = ref.watch(jan3AuthProvider(walletId)).valueOrNull?.profile;

  final isBoundToOtherWallet =
      profile?.fingerprint != null && profile?.fingerprint != walletId;
  if (isBoundToOtherWallet) return null;

  final address = profile?.lnUsername;
  if (address == null || address.isEmpty) return null;

  return LightningAddressState(
    address: address,
    isToggled: profile!.lnAddressToggled,
  );
});

extension LightningAddressStateX on LightningAddressState? {
  /// Whether the user has a lightning address registered.
  bool get isRegistered => this != null;

  /// Whether the lightning address is registered and toggled on.
  bool get isActive => this?.isToggled == true;
}

/// `true` = Boltz invoice flow; `false` = lightning address receive when available.
final lnReceiveModeProvider =
    AutoDisposeNotifierProvider<LnReceiveModeNotifier, bool>(
  LnReceiveModeNotifier.new,
);

class LnReceiveModeNotifier extends AutoDisposeNotifier<bool> {
  @override
  bool build() {
    final walletId = ref.watch(currentWalletIdSyncProvider);
    final profile = ref.watch(jan3AuthProvider(walletId)).valueOrNull?.profile;
    final hasActivatedLnAddress = profile?.lnUsername != null &&
        profile!.lnUsername!.isNotEmpty &&
        profile.lnAddressToggled;
    return !hasActivatedLnAddress;
  }

  void toggle() => state = !state;

  void setInvoiceMode() => state = true;

  void setAddressMode() => state = false;
}
