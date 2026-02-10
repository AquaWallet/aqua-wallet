import 'package:aqua/data/data.dart';
import 'package:aqua/features/changelly/changelly.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';

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
    final formatter = ref.read(formatProvider);
    final fiat = ref.read(fiatProvider);
    final displayUnits = ref.read(displayUnitsProvider);

    return {
      SwapServiceSource.sideshift: SideshiftService(
        httpProvider: SideshiftHttpProvider(),
        storageProvider: storage,
        formatter: formatter,
        fiatProvider: fiat,
        displayUnitsProvider: displayUnits,
      ),
      SwapServiceSource.changelly: ChangellyService(
        apiService: ChangellyApiService(dio),
        storageProvider: storage,
        formatter: formatter,
        fiatProvider: fiat,
        displayUnitsProvider: displayUnits,
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
