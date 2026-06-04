import 'package:aqua/data/data.dart';
import 'package:aqua/features/account/providers/jan3_auth_provider.dart';
import 'package:aqua/features/feature_flags/providers/setup_config_provider.dart';
import 'package:aqua/features/lightning_address/models/models.dart';
import 'package:aqua/features/lightning_address/services/services.dart';
import 'package:aqua/features/shared/providers/current_wallet_provider.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';

final _logger = CustomLogger(FeatureFlag.jan3Account);

final lnAddressRegistrationProvider =
    AsyncNotifierProvider<LnAddressRegistrationNotifier, void>(
        LnAddressRegistrationNotifier.new);

class LnAddressRegistrationNotifier extends AsyncNotifier<void> {
  static const _bootLightningAddressesCount =
      5; // Number of addresses to register the frist time

  @override
  Future<void> build() async {
    final isEnabled = ref.watch(lnAddressRemoteFlagProvider);
    if (!isEnabled) return;

    await ref.read(storedWalletsProvider.future);
    final walletId = ref.read(currentWalletIdSyncProvider);
    if (walletId.isEmpty) {
      _logger.debug('[LnRegistration] Skipped: no current wallet');
      return;
    }

    final authState = await ref.watch(jan3AuthProvider(walletId).future);
    _logger.debug('[LnRegistration] Auth state: ${authState.runtimeType}');

    final profile = authState.profile;
    if (profile == null) {
      _logger.debug('[LnRegistration] Skipped: not authenticated');
      return;
    }
    if (profile.lnUsername == null || profile.lnUsername!.isEmpty) {
      _logger.debug('[LnRegistration] Skipped: lnUsername is null or empty');
      return;
    }
    // Auth provider detects the mismatch in _refreshProfileData() and sets
    // pendingWalletRebind. Address registration is skipped until rebind is
    // confirmed — at which point _forceRegisterAddresses(overrideFingerprint: true)
    // is called and the auth provider signs out the previously-bound wallet.
    final isBoundToOtherWallet =
        profile.fingerprint != null && profile.fingerprint != walletId;
    if (isBoundToOtherWallet) return;

    if (!profile.lnAddressToggled) {
      _logger.debug('[LnRegistration] Skipped: lnAddress not toggled on');
      return;
    }

    if (profile.newAddressesNeeded <= 0) {
      _logger.debug(
          '[LnRegistration] Skipped: newAddressesNeeded=${profile.newAddressesNeeded}');
      return;
    }

    _logger.info(
        '[LnRegistration] Registering ${profile.newAddressesNeeded} addresses');
    try {
      await _registerAddresses(profile.newAddressesNeeded, walletId);
      _logger.info('[LnRegistration] Successfully registered addresses');
    } catch (e, st) {
      _logger.error('[LnRegistration] Failed: $e', e, st);
      rethrow;
    }
  }

  Future<void> activate() => _forceRegisterAddresses();

  Future<void> _forceRegisterAddresses() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(storedWalletsProvider.future);
      final walletId = ref.read(currentWalletIdSyncProvider);
      if (walletId.isEmpty) {
        _logger.debug('[LnRegistration] Skipped: no current wallet');
        throw Exception('No current wallet');
      }
      await _registerAddresses(_bootLightningAddressesCount, walletId,
          overrideFingerprint: true);
      // Use refreshAfterRebind (not invalidate) so _refreshProfileData runs,
      // which calls _signOutConflictingWallets now that fingerprints match.
      await ref.read(jan3AuthProvider(walletId).notifier).refreshAfterRebind();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      _logger.error('[LnRegistration] Failed: $e', e, st);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> _registerAddresses(int count, String fingerPrint,
      {bool overrideFingerprint = false}) async {
    _logger.debug(
        '[LnRegistration] Registering $count addresses with fingerPrint: $fingerPrint');

    final addresses = await _generateLnAddresses(count);
    _logger.debug('[LnRegistration] Generated ${addresses.length} addresses');

    final api = ref.read(jan3ApiLightningAddressesProvider);
    final response = await api.registerAddresses(
      RegisterAddressesRequest(
        fingerPrint: fingerPrint,
        addresses: addresses,
      ),
      overrideFingerprint: overrideFingerprint,
    );

    if (!response.isSuccessful) {
      throw Exception(
          'Failed to register addresses: ${response.statusCode} ${response.error}');
    }
  }

  Future<List<String>> _generateLnAddresses(int count) async {
    final addresses = <String>[];
    for (var i = 0; i < count; i++) {
      final result = await ref.read(liquidProvider).getReceiveAddress();
      if (result?.address != null) {
        addresses.add(result!.address!);
      }
    }
    return addresses;
  }
}
