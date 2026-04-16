import 'dart:async';

import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/fiat_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/lwk_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/providers/transactions_storage_provider.dart';
import 'package:aqua/features/wallet/providers/wallet_utils.dart';
import 'package:aqua/gdk.dart';
import 'package:aqua/logger.dart';
import 'package:rxdart/rxdart.dart';

const kConnectionTimeout = Duration(seconds: 5);

final aquaConnectionProvider =
    AsyncNotifierProvider<AquaConnectionNotifier, void>(
        AquaConnectionNotifier.new);

class AquaConnectionNotifier extends AsyncNotifier<void> {
  bool _isListenining = false; // Whether connectivity event listener was added
  @override
  FutureOr<void> build() {
    // Don't start listening to connectivity changes immediately
    // Wait until after the first connect() call completes
    return null;
  }

  // Helper method to invalidate rate/price providers
  void _refreshRateProviders() {
    logger.debug('[AquaConnectionNotifier] Refreshing rate/price providers...');
    ref.invalidate(btcPriceProvider);
    ref.invalidate(gdkCurrenciesProvider);
    ref.invalidate(gdkSettingsProvider);
    ref.invalidate(exchangeRatesProvider);
    ref.invalidate(fiatRatesProvider);
    ref.invalidate(fiatProvider);
  }

  Future<void> connect() async {
    state = const AsyncValue.loading();

    await disconnect();

    try {
      final (currentWalletId, _) = await ref
          .read(secureStorageProvider)
          .get(StorageKeys.currentWalletId);
      if (currentWalletId == null) {
        throw Exception('Falied to get current wallet ID');
      }

      final (mnemonic, err) = await ref
          .read(secureStorageProvider)
          .get(StorageKeys.mnemonic(currentWalletId));
      if (err != null || mnemonic == null) {
        throw AquaProviderInvalidMnemonicException();
      }

      final credentials = GdkLoginCredentials(mnemonic: mnemonic);

      // Connect to Liquid with timeout
      await ref.read(liquidProvider).connect().timeout(
        kConnectionTimeout,
        onTimeout: () {
          logger.warning('[AquaConnectionProvider] Liquid connection timeout');
          return false;
        },
      );
      final liquidWalletId =
          await ref.read(liquidProvider).loginUser(credentials: credentials);
      if (liquidWalletId == null || liquidWalletId.isEmpty) {
        throw AquaProviderLiquidAuthFailureException();
      }

      // Connect to Bitcoin with timeout
      await ref.read(bitcoinProvider).connect().timeout(
        kConnectionTimeout,
        onTimeout: () {
          logger.warning('[AquaConnectionProvider] Bitcoin connection timeout');
          return false;
        },
      );
      final bitcoinWalletId =
          await ref.read(bitcoinProvider).loginUser(credentials: credentials);
      if (bitcoinWalletId == null || bitcoinWalletId.isEmpty) {
        throw AquaProviderBitcoinAuthFailureException();
      }
      final subaccount = await ref.read(bitcoinProvider).getSubaccount(1);
      if (subaccount == null) {
        await ref.read(bitcoinProvider).createSegwitSubaccount();
      }
      final liquidSubaccounts = await ref.read(liquidProvider).getSubaccounts();
      if (liquidSubaccounts == null || liquidSubaccounts.isEmpty) {
        throw AquaProviderLiquidAuthFailureException();
      }
      // Get the core descriptors for the Liquid subaccount
      final liquidCoreDescriptors = liquidSubaccounts[0].coreDescriptors;
      if (liquidCoreDescriptors == null || liquidCoreDescriptors.isEmpty) {
        throw AquaProviderLiquidAuthFailureException();
      }
      // assuming the first descriptor is the CtDescriptor
      final ctDescriptor = liquidCoreDescriptors[0];
      final ctDescriptorWithChangePath =
          WalletUtils.addChangePathToDescriptor(ctDescriptor);
      await ref.read(lwkProvider).init();
      await ref.read(lwkProvider).loginUser(
          credentials: credentials,
          liquidCtDescriptor: ctDescriptorWithChangePath);

      ref.read(lwkProvider).syncWallet();
      // Initialize the network event stream after successful connection
      ref.read(aquaProvider).initNetworkEventStream();

      logger.debug('[AquaConnectionProvider] Connected');

      // Start listening to connectivity changes events after
      // initial connection has been established
      _startConnectivityListening();

      // Refresh price and rate providers using the helper method
      _refreshRateProviders();
      state = const AsyncValue.data(null);
    } catch (error) {
      logger.debug('[AquaConnectionProvider] Failed to connect');
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  Future<void> disconnect() async {
    logger.debug('[AquaConnectionNotifier] Starting disconnect...');

    // Close network event stream first to prevent new events
    try {
      final aquaProviderInstance = ref.read(aquaProvider) as _AquaProvider;
      // Cancel subscription first
      await aquaProviderInstance._networkEventSubscription?.cancel();
      // Then close the subject
      if (!aquaProviderInstance._networkEventSubject.isClosed) {
        await aquaProviderInstance._networkEventSubject.close();
      }
    } catch (e) {
      logger.warning(
          '[AquaConnectionNotifier] Error closing network event stream: $e');
    }

    // Disconnect network providers
    await ref.read(liquidProvider).disconnect();
    await ref.read(bitcoinProvider).disconnect();
    await ref.read(lwkProvider).disconnect();

    logger.debug('[AquaConnectionNotifier] Disconnect completed');
  }

  /// Complete cleanup of all wallet-related providers and state
  Future<void> fullCleanup() async {
    logger.debug('[AquaConnectionNotifier] Starting full cleanup...');
    try {
      // Check if we have any current wallet - if not, we might already be in clean state
      final (currentWalletId, _) = await ref
          .read(secureStorageProvider)
          .get(StorageKeys.currentWalletId);

      if (currentWalletId == null) {
        logger.debug(
            '[AquaConnectionNotifier] No current wallet found, performing minimal cleanup...');

        // Just ensure we're disconnected and invalidate key providers
        try {
          await ref.read(liquidProvider).disconnect();
          await ref.read(bitcoinProvider).disconnect();
          await ref.read(lwkProvider).disconnect();
        } catch (e) {
          logger.debug(
              '[AquaConnectionNotifier] Providers already disconnected: $e');
        }

        // Minimal provider invalidation
        ref.invalidate(transactionStorageProvider);
        ref.invalidate(assetsProvider);

        logger.debug('[AquaConnectionNotifier] Minimal cleanup completed');
        return;
      }

      // Full cleanup when we have a current wallet
      logger.debug(
          '[AquaConnectionNotifier] Current wallet found, performing full cleanup...');

      // 1. Disconnect network connections first
      await disconnect();

      // 2. Wait a bit for network operations to settle
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Invalidate all related providers to force cleanup
      ref.invalidate(transactionStorageProvider);
      ref.invalidate(assetsProvider);
      ref.invalidate(btcPriceProvider);
      ref.invalidate(gdkCurrenciesProvider);
      ref.invalidate(gdkSettingsProvider);
      ref.invalidate(exchangeRatesProvider);
      ref.invalidate(fiatRatesProvider);
      ref.invalidate(fiatProvider);

      // 4. Clear transaction storage from memory
      try {
        await ref.read(transactionStorageProvider.notifier).clearFromMemory();
      } catch (e) {
        logger.warning(
            '[AquaConnectionNotifier] Error clearing transaction storage: $e');
      }

      // 5. Wait for invalidations to complete
      await Future.delayed(const Duration(milliseconds: 300));

      logger.debug('[AquaConnectionNotifier] Full cleanup completed');
    } catch (e, stack) {
      logger.error(
          '[AquaConnectionNotifier] Error during full cleanup: $e\n$stack');
      rethrow;
    }
  }

  void _startConnectivityListening() {
    if (_isListenining) return; // Prevent multiple listeners

    _isListenining = true;

    // Listen to connectivity changes
    ref.listen(connectivityStatusProvider, (_, data) {
      if (data.valueOrNull == true) {
        // Connected to network
        ref.read(bitcoinProvider).reconnectHint(hint: GdkReconnectHint.connect);
        ref.read(liquidProvider).reconnectHint(hint: GdkReconnectHint.connect);

        // Refresh price and rate providers using the helper method
        _refreshRateProviders();
      } else {
        // Disconnected from network
        ref
            .read(bitcoinProvider)
            .reconnectHint(hint: GdkReconnectHint.disconnect);
        ref
            .read(liquidProvider)
            .reconnectHint(hint: GdkReconnectHint.disconnect);
      }
    });
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

final aquaProvider = Provider<AquaProvider>((ref) => _AquaProvider(ref));

abstract class AquaProvider {
  late final Stream<AsyncValue<List<GdkNetworkEventStateEnum?>>>
      networkEventStream;
  Future<Asset?> liquidAssetById(String id);
  Stream<int> getConfirmationCount({
    required Asset asset,
    required int transactionBlockHeight,
  });
  Future<GdkCurrencyData?> getAvailableCurrencies();
  Future<void> clearSecureStorageOnReinstall();
  Future<GdkAssetInformation?> gdkRawAssetForAssetId(String id);
  void initNetworkEventStream();
}

class _AquaProvider extends AquaProvider {
  _AquaProvider(
    this.ref,
  );

  final ProviderRef ref;
  StreamSubscription? _networkEventSubscription;

  @override
  Future<GdkAssetInformation?> gdkRawAssetForAssetId(String id) async {
    final allAssets = await ref.read(liquidProvider).getAssets();
    final asset = allAssets?[id];

    return asset;
  }

  @override
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
        logoUrl: UiAssets.assetIcons.liquid.path,
      );
    }

    return null;
  }

  @override
  Stream<int> getConfirmationCount(
      {required Asset asset, required int transactionBlockHeight}) {
    if (transactionBlockHeight == 0) return Stream.value(0);

    return Stream.value(asset).switchMap((asset) {
      return ref
          .read(asset.isBTC ? bitcoinProvider : liquidProvider)
          .blockHeightEventSubject;
    }).map((currentBlockHeight) {
      if (currentBlockHeight == 0 ||
          currentBlockHeight < transactionBlockHeight) {
        // Mined (blockHeight > 0) but the block-height stream hasn't caught
        // up yet — report at least 1 so the tx isn't stuck as "pending".
        return 1;
      }
      return currentBlockHeight - transactionBlockHeight + 1;
    });
  }

  @override
  Future<GdkCurrencyData?> getAvailableCurrencies() async {
    return ref.read(liquidProvider).getAvailableCurrencies();
  }

  /// --------------------------------------------------------------------------------------------
  /// Connection Related
  /// --------------------------------------------------------------------------------------------
  // Private subject to control the stream lifecycle
  late BehaviorSubject<AsyncValue<List<GdkNetworkEventStateEnum?>>>
      _networkEventSubject =
      BehaviorSubject<AsyncValue<List<GdkNetworkEventStateEnum?>>>();

  // Method to initialize or refresh the stream
  @override
  void initNetworkEventStream() {
    // Cancel previous subscription first
    _networkEventSubscription?.cancel();

    // Close previous stream if it exists
    if (!_networkEventSubject.isClosed) {
      _networkEventSubject.close();
    }

    // Create a new subject
    _networkEventSubject =
        BehaviorSubject<AsyncValue<List<GdkNetworkEventStateEnum?>>>();

    // Set up the combined stream
    _networkEventSubscription = Rx.combineLatest<GdkNetworkEventStateEnum?,
            List<GdkNetworkEventStateEnum?>>([
      ref.read(liquidProvider).gdkNetworkEventSubject,
      ref.read(bitcoinProvider).gdkNetworkEventSubject
    ], (e) => e)
        .doOnData((value) =>
            logger.debug('[NetworkEvent] Connection state changed to: $value'))
        .map<AsyncValue<List<GdkNetworkEventStateEnum?>>>(
            (value) => AsyncValue.data(value))
        .startWith(const AsyncValue.loading())
        .onErrorReturnWith(
            (error, stackTrace) => AsyncValue.error(error, stackTrace))
        .listen(
      (value) {
        if (!_networkEventSubject.isClosed) {
          _networkEventSubject.add(value);
        }
      },
      onError: (error, stackTrace) {
        if (!_networkEventSubject.isClosed) {
          _networkEventSubject.addError(error, stackTrace);
        }
      },
    );
  }

  // Public stream that consumers can listen to
  @override
  Stream<AsyncValue<List<GdkNetworkEventStateEnum?>>> get networkEventStream =>
      _networkEventSubject.stream;

  @override
  Future<void> clearSecureStorageOnReinstall() async {
    const key = 'isFirstRun';
    final prefs = ref.read(sharedPreferencesProvider);
    final isFirstRun = prefs.getBool(key) ?? true;

    if (isFirstRun) {
      await ref.read(secureStorageProvider).deleteAll();
      prefs.setBool(key, false);
      logger.debug('[Aqua] Clearing secure storage on first run');
    }
  }
}

/// --------------------------------------------------------------------------------------------
/// Exceptions
/// --------------------------------------------------------------------------------------------
class AquaProviderInvalidMnemonicException implements Exception {}

class AquaProviderLiquidAuthFailureException implements Exception {}

class AquaProviderBitcoinAuthFailureException implements Exception {}

class AquaProviderLWKAuthFailureException implements Exception {}

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
