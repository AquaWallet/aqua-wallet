import 'dart:developer';

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
  final bool runTestCode = false;

  final PublishSubject<void> _startAuthSubject = PublishSubject();
  late final Stream<void> _startAuthStream = _startAuthSubject.switchMap((_) =>
      authStream.first.asStream().switchMap<void>((value) => value.maybeWhen(
            loading: () => const Stream.empty(),
            orElse: () => Stream.value(null),
          )));

  late final Stream<AsyncValue<String>> mnemonicStringStream = _startAuthStream
      .startWith(null)
      .switchMap((_) => Stream.value(_)
          .asyncMap((_) => getMnemonic())
          .map((mnemonic) => AsyncValue.data(mnemonic))
          .startWith(const AsyncValue.loading())
          .onErrorReturnWith(
              (error, stackTrace) => AsyncValue.error(error, stackTrace)))
      .shareReplay(maxSize: 1);

  late final Stream<AsyncValue<void>> authStream = mnemonicStringStream
      .switchMap((value) => value.when(
            data: (mnemonic) => Stream.value(mnemonic)
                .asyncMap((_) async => await disconnect())
                .asyncMap((_) => Rx.zipList([
                      Stream.value(null)
                          .asyncMap((_) async =>
                              await ref.read(liquidProvider).connect())
                          .asyncMap((_) async {
                            return GdkLoginCredentials(mnemonic: mnemonic);
                          })
                          .asyncMap((credentials) => ref
                              .read(liquidProvider)
                              .loginUser(credentials: credentials))
                          .asyncMap<void>((id) async {
                            if (id == null || id.isEmpty) {
                              throw AquaProviderLiquidAuthFailureException();
                            }
                            await ref.read(liquidProvider).refreshAssets();
                            return;
                          }),
                      Stream.value(null)
                          .asyncMap((_) async =>
                              await ref.read(bitcoinProvider).connect())
                          .asyncMap((_) async {
                            return GdkLoginCredentials(mnemonic: mnemonic);
                          })
                          .asyncMap((credentials) => ref
                              .read(bitcoinProvider)
                              .loginUser(credentials: credentials))
                          .asyncMap<void>((id) async {
                            if (id == null || id.isEmpty) {
                              throw AquaProviderBitcoinAuthFailureException();
                            }
                            final subaccount = await ref
                                .read(bitcoinProvider)
                                .getSubaccount(1);
                            if (subaccount == null) {
                              await ref
                                  .read(bitcoinProvider)
                                  .createSegwitSubaccount();
                            }

                            await ref.read(bitcoinProvider).refreshAssets();

                            return;
                          }),
                    ]).first)
                .map<AsyncValue<void>>((_) => const AsyncValue.data(null))
                .startWith(const AsyncValue.loading())
                .onErrorReturnWith(
                    (error, stackTrace) => AsyncValue.error(error, stackTrace)),
            loading: () => Stream.value(const AsyncValue<void>.loading()),
            error: (error, stackTrace) =>
                Stream.value(AsyncValue<void>.error(error, stackTrace)),
          ))
      .shareReplay(maxSize: 1);

  void authorize() {
    _startAuthSubject.add(null);
  }

  Future<void> disconnect() => Rx.zipList([
        Stream.value(null).asyncMap(
            (event) async => await ref.read(liquidProvider).disconnect()),
        Stream.value(null).asyncMap(
            (event) async => await ref.read(bitcoinProvider).disconnect()),
      ]).asyncMap<void>((_) {
        return null;
      }).first;

  Future<String> getMnemonic() async {
    final (value, err) =
        await ref.read(secureStorageProvider).get(StorageKeys.mnemonic);
    if (err != null) {
      throw AquaProviderInvalidMnemonicException();
    }

    return value!;
  }

  Future<Map<String, GdkAssetInformation>?> _gdkRawAssets() => authStream
      .switchMap<void>((value) => value.maybeWhen(
            data: (_) => Stream.value(null),
            orElse: () => const Stream.empty(),
          ))
      .asyncMap((_) => ref.read(liquidProvider).getAssets())
      .handleError((e, stackTrace) {})
      .first;

  Future<Asset?> liquidAssetById(String id) =>
      _gdkRawAssets().then((gdkAssets) => gdkAssets?[id]).then(
          (gdkAsset) => gdkAsset != null ? _buildLiquidAsset(gdkAsset) : null);

  Future<GdkAssetInformation?> gdkRawAssetForAssetId(String assetId) {
    return Stream.value(null).asyncMap((_) async {
      return _gdkRawAssets();
    }).map((gdkAssets) {
      return gdkAssets?.values ?? <GdkAssetInformation>[];
    }).asyncMap((gdkAssets) async {
      if (gdkAssets.any((asset) => asset.assetId == assetId)) {
        return gdkAssets.firstWhere((asset) => asset.assetId == assetId);
      }

      return null;
    }).first;
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

  Asset _buildLiquidAsset(GdkAssetInformation gdkAsset, {int balance = 0}) {
    return Asset(
      id: gdkAsset.assetId ?? '',
      amount: balance,
      name: gdkAsset.name ?? '',
      ticker: gdkAsset.ticker ?? '',
      precision: gdkAsset.precision ?? 8,
      domain: gdkAsset.entity?.domain,
      isLiquid: true,
      isLBTC: ref.read(liquidProvider).policyAsset == gdkAsset.assetId,
      isUSDt: ref.read(liquidProvider).usdtId == gdkAsset.assetId,
      logoUrl: Svgs.liquidAsset,
    );
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
      log('[Aqua] Clearing secure storage on first run');
    }
  }

  /// --------------------------------------------------------------------------------------------
  /// Init
  /// --------------------------------------------------------------------------------------------
}

/// --------------------------------------------------------------------------------------------
/// Exceptions
/// --------------------------------------------------------------------------------------------
class AquaProviderUnathorizedException implements Exception {}

class AquaProviderInvalidMnemonicException implements Exception {}

class AquaProviderBiometricFailureException implements Exception {}

class AquaProviderLiquidAuthFailureException implements Exception {}

class AquaProviderBitcoinAuthFailureException implements Exception {}

class AquaProviderAssetForAssetIdEmptyException implements Exception {}

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
