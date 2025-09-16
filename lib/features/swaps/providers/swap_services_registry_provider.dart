import 'package:coin_cz/features/changelly/changelly.dart';
import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideshift/sideshift.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/logger.dart';

class UnsupportedSwapAssetException implements Exception {
  final Asset asset;
  UnsupportedSwapAssetException(this.asset);

  @override
  String toString() =>
      'No preferred swap service configured for asset: ${asset.ticker}';
}

/// Initializes and caches swap services
class SwapServicesRegistryNotifier
    extends Notifier<Map<SwapServiceSource, SwapService>> {
  final _logger = CustomLogger(FeatureFlag.swap);

  @override
  Map<SwapServiceSource, SwapService> build() {
    _logger.debug('Initializing swap services registry');

    final storage = ref.read(swapStorageProvider.notifier);
    final dio = ref.read(dioProvider);

    return {
      SwapServiceSource.sideshift: SideshiftService(
        httpProvider: SideshiftHttpProvider(),
        storageProvider: storage,
      ),
      SwapServiceSource.changelly: ChangellyService(
        apiService: ChangellyApiService(dio),
        storageProvider: storage,
      ),
    };
  }

  SwapService getService(SwapServiceSource type) {
    if (!state.containsKey(type)) {
      throw StateError('Service not initialized: ${type.displayName}');
    }
    return state[type]!;
  }
}

final swapServicesRegistryProvider = NotifierProvider<
    SwapServicesRegistryNotifier, Map<SwapServiceSource, SwapService>>(
  SwapServicesRegistryNotifier.new,
);

final swapServiceProvider = Provider.family<SwapService, SwapServiceSource>(
  (ref, type) {
    final registry = ref.watch(swapServicesRegistryProvider);
    if (!registry.containsKey(type)) {
      throw StateError('Service not initialized: ${type.displayName}');
    }
    return registry[type]!;
  },
);
