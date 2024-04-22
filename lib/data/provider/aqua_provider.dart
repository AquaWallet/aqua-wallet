import 'dart:async';

import 'package:aqua/logger.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/data/provider/secure_storage_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gdk.dart';
import 'package:rxdart/rxdart.dart';

final aquaConnectionProvider =
    AsyncNotifierProvider<AquaConnectionProvider, void>(
        AquaConnectionProvider.new);

class AquaConnectionProvider extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> connect() async {
    state = const AsyncValue.loading();

    await disconnect();

    try {
      final (mnemonic, err) =
          await ref.read(secureStorageProvider).get(StorageKeys.mnemonic);
      if (err != null || mnemonic == null) {
        throw AquaProviderInvalidMnemonicException();
      }

      final credentials = GdkLoginCredentials(mnemonic: mnemonic);

      await ref.read(liquidProvider).connect();
      final liquidWalletId =
          await ref.read(liquidProvider).loginUser(credentials: credentials);
      if (liquidWalletId == null || liquidWalletId.isEmpty) {
        throw AquaProviderLiquidAuthFailureException();
      }

      await ref.read(bitcoinProvider).connect();
      final bitcoinWalletId =
          await ref.read(bitcoinProvider).loginUser(credentials: credentials);
      if (bitcoinWalletId == null || bitcoinWalletId.isEmpty) {
        throw AquaProviderBitcoinAuthFailureException();
      }
      final subaccount = await ref.read(bitcoinProvider).getSubaccount(1);
      if (subaccount == null) {
        await ref.read(bitcoinProvider).createSegwitSubaccount();
      }

      logger.d('[AquaConnectionProvider] Connected');

      state = const AsyncValue.data(null);
    } catch (error) {
      logger.d('[AquaConnectionProvider] Failed to connect');
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  Future<void> disconnect() async {
    await ref.read(liquidProvider).disconnect();
    await ref.read(bitcoinProvider).disconnect();
  }
}

/// # Connection flow description
/// (network name)_provider is derived from [NetworkFrontend]
/// (network name)_network is derived from [NetworkSession]
///
/// [NetworkFrontend] calling [NetworkBackend] which is placed in separate isolate
/// and will use `session` to call [LibGdk] wrapper on gdk ffi functions.
///
/// (network name)_provider can be called directly but preffered way
/// is to group all network providers in [AquaProvider].
/// [AquaProvider] should manage all network providers.
///
/// ## Flow
/// [NetworkFrontend] -> isolate -> [NetworkBackend] -> [NetworkSession] -> [LibGdk]
///
/// ## Returned values
/// Values returned from [LibGdk] are wrapped in [Result]
/// which could contain value or error.
///
/// [Result.error] must be handled in [NetworkBackend].
/// [Result.error] cannot be sent over isolate - causes crash.
/// Unwrapped `null` values cannot be also sent over isolate - causes crash.
///
/// [NetworkFrontend] will always receive value (mostly bool) or
/// [Result.value] in other cases.
/// [Result.value] could contain value or null in case of error in backend.
///
/// ## Beware
/// All (network name)_provider's initialize [NetworkBackend] derived classes.
/// Since the base class always has the same name, and __isolator package__
/// recognize receiver by base class name id we should always use our own uniqueId
/// during backend initialization!

final aquaProvider = Provider<AquaProvider>((ref) => AquaProvider(ref));

class AquaProvider {
  AquaProvider(
    this.ref,
  );

  final ProviderRef ref;

  Future<GdkAssetInformation?> gdkRawAssetForAssetId(String id) async {
    final allAssets = await ref.read(liquidProvider).getAssets();
    final asset = allAssets?[id];

    return asset;
  }

  Future<Asset?> liquidAssetById(String id) async {
    final asset = await gdkRawAssetForAssetId(id);
    if (asset != null) {
      return Asset(
        id: asset.assetId ?? '',
        amount: 0,
        name: asset.name ?? '',
        ticker: asset.ticker ?? '',
        precision: asset.precision ?? 8,
        domain: asset.entity?.domain,
        isLiquid: true,
        isLBTC: ref.read(liquidProvider).policyAsset == asset.assetId,
        isUSDt: ref.read(liquidProvider).usdtId == asset.assetId,
        logoUrl: Svgs.liquidAsset,
      );
    }

    return null;
  }

  Stream<int> getConfirmationCount(
      {required Asset asset, required int transactionBlockHeight}) {
    return Stream.value(asset).switchMap((asset) {
      return asset.isBTC
          ? ref.read(bitcoinProvider).blockHeightEventSubject
          : ref.read(liquidProvider).blockHeightEventSubject;
    }).map((currentBlockHeight) {
      return (transactionBlockHeight == 0)
          ? 0
          : currentBlockHeight - transactionBlockHeight + 1;
    });
  }

  Future<GdkCurrencyData?> getAvailableCurrencies() async {
    return ref.read(liquidProvider).getAvailableCurrencies();
  }

  /// --------------------------------------------------------------------------------------------
  /// Connection Related
  /// --------------------------------------------------------------------------------------------
  late final Stream<AsyncValue<List<GdkNetworkEventStateEnum?>>>
      networkEventStream = Rx.combineLatest<GdkNetworkEventStateEnum?,
              List<GdkNetworkEventStateEnum?>>([
    ref.read(liquidProvider).gdkNetworkEventSubject,
    ref.read(bitcoinProvider).gdkNetworkEventSubject
  ], (e) => e)
          .doOnData((value) => logger.d('Connection changed to: $value'))
          .map<AsyncValue<List<GdkNetworkEventStateEnum?>>>(
              (value) => AsyncValue.data(value))
          .startWith(const AsyncValue.loading())
          .onErrorReturnWith(
              (error, stackTrace) => AsyncValue.error(error, stackTrace))
          .shareReplay(maxSize: 1);

  Future<void> clearSecureStorageOnReinstall() async {
    const key = 'isFirstRun';
    final prefs = ref.read(sharedPreferencesProvider);
    final isFirstRun = prefs.getBool(key) ?? true;

    if (isFirstRun) {
      await ref.read(secureStorageProvider).deleteAll();
      prefs.setBool(key, false);
      logger.d('[Aqua] Clearing secure storage on first run');
    }
  }
}

/// --------------------------------------------------------------------------------------------
/// Exceptions
/// --------------------------------------------------------------------------------------------
class AquaProviderInvalidMnemonicException implements Exception {}

class AquaProviderLiquidAuthFailureException implements Exception {}

class AquaProviderBitcoinAuthFailureException implements Exception {}

/// --------------------------------------------------------------------------------------------
/// networkEventStreamProvider
/// --------------------------------------------------------------------------------------------
final _networkEventStreamProvider =
    StreamProvider.autoDispose<AsyncValue<List<GdkNetworkEventStateEnum?>>>(
        (ref) async* {
  yield* ref.watch(aquaProvider).networkEventStream;
});

final networkEventStreamProvider =
    Provider.autoDispose<AsyncValue<List<GdkNetworkEventStateEnum?>>?>((ref) {
  return ref.watch(_networkEventStreamProvider).asData?.value;
});
