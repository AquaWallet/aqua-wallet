import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/feature_flags/services/feature_flags_service.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:package_info_plus/package_info_plus.dart';

final enabledServicesTypesProvider = AsyncNotifierProvider<
    EnabledServicesTypesNotifier,
    List<MarketplaceServiceAvailability>>(EnabledServicesTypesNotifier.new);

class EnabledServicesTypesNotifier
    extends AsyncNotifier<List<MarketplaceServiceAvailability>> {
  @override
  Future<List<MarketplaceServiceAvailability>> build() async {
    final isMockDataEnabled =
        ref.read(featureFlagsProvider).marketplaceTilesMockDataEnabled;

    // If mock data is enabled, return all services as enabled
    if (isMockDataEnabled) {
      return _getMockMarketplaceServices();
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final regionProvider = ref.read(regionsProvider);
    final featureFlagService =
        await ref.read(featureFlagsServiceProvider.future);

    final response = await featureFlagService.getMarketPlaceTiles(
      region: regionProvider.currentRegion?.iso,
      buildNumber: packageInfo.buildNumber,
    );

    if (response.statusCode != 200 || response.body == null) {
      throw Exception('An error occurred trying to get the available services');
    }

    final tiles = response.body!;
    final allServices = tiles
        .map(MarketplaceServiceAvailability.fromResponse)
        .whereType<MarketplaceServiceAvailability>()
        .toList();

    return allServices;
  }

  bool isTileEnabled(MarketplaceServiceType type) {
    return state.value?.firstWhereOrNull((e) => e.type == type)?.isEnabled ??
        false;
  }

  /// Returns mock marketplace services with all tiles enabled for testing
  List<MarketplaceServiceAvailability> _getMockMarketplaceServices() {
    return MarketplaceServiceType.values
        .map(
          (type) => MarketplaceServiceAvailability(
            type: type,
            isEnabled: true,
          ),
        )
        .toList();
  }
}
