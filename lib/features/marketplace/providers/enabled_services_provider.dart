import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/marketplace/api_services/marketplace_service.dart';
import 'package:aqua/features/marketplace/models/models.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

final enabledServicesTypesProvider = AsyncNotifierProvider.autoDispose<
    EnabledServicesTypesNotifier,
    List<MarketplaceServiceAvailability>>(EnabledServicesTypesNotifier.new);

class EnabledServicesTypesNotifier
    extends AutoDisposeAsyncNotifier<List<MarketplaceServiceAvailability>> {
  @override
  Future<List<MarketplaceServiceAvailability>> build() async {
    final isMockDataEnabled =
        ref.read(featureFlagsProvider).marketplaceTilesMockDataEnabled;

    // If mock data is enabled, return all services as enabled
    if (isMockDataEnabled) {
      return _getMockMarketplaceServices();
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final featureFlagService = ref.read(marketplaceServiceProvider);
    final String? os = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };

    final response = await featureFlagService.getMarketPlaceTiles(
      buildNumber: packageInfo.buildNumber,
      os: os,
    );

    if (response.statusCode != 200 || response.body == null) {
      throw Exception('An error occurred trying to get the available services');
    }

    final tiles = response.body!;
    final allServices = tiles
        .map(MarketplaceServiceAvailability.fromResponse)
        .whereType<MarketplaceServiceAvailability>()
        .toList();

    final currentRegion =
        ref.watch(regionsProvider.select((p) => p.currentRegion));

    return allServices.where((service) {
      if (!service.isEnabled) return false;
      final regions = RegionsIntegrations.supportedRegions(service.type);
      if (regions == null) return true;
      if (currentRegion == null) return false;
      return regions.any((r) => r.iso == currentRegion.iso);
    }).toList();
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
