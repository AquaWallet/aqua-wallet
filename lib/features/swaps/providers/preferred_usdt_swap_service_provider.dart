import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';

/// Resolves the preferred USDT service type
final preferredUsdtSwapServiceProvider =
    AsyncNotifierProvider<PreferredUsdtServiceNotifier, SwapServiceSource>(
  PreferredUsdtServiceNotifier.new,
);

class PreferredUsdtServiceNotifier extends AsyncNotifier<SwapServiceSource> {
  final _logger = CustomLogger(FeatureFlag.swap);

  @override
  Future<SwapServiceSource> build() async {
    final useChangelly =
        ref.watch(featureFlagsProvider).changellyForUSDtSwapsEnabled;
    _logger.debug(
        'Determining preferred USDt service (Changelly feature flag: $useChangelly)');
    if (useChangelly) {
      return SwapServiceSource.changelly;
    }

    // sideshift blocks U.S. IPs
    final isSideshiftAvailable = await checkSideshiftAvailability();
    if (!isSideshiftAvailable) {
      _logger.debug(
          'Determining preferred USDt service (Changelly feature flag: $useChangelly)');
      return SwapServiceSource.changelly;
    }

    // Default to Sideshift
    return SwapServiceSource.sideshift;
  }

  /// Checks if Sideshift is available and has necessary permissions
  Future<bool> checkSideshiftAvailability() async {
    try {
      final sideshiftService =
          ref.read(swapServicesRegistryProvider)[SwapServiceSource.sideshift];

      if (sideshiftService == null) {
        _logger.error('Sideshift service not initialized');
        return false;
      }

      final hasSideshiftPermissions = await sideshiftService.checkPermissions();

      _logger.debug(
          'Sideshift permissions check result: $hasSideshiftPermissions');
      return hasSideshiftPermissions;
    } catch (e) {
      _logger.error('Error checking Sideshift permissions: $e');
      return false;
    }
  }
}
