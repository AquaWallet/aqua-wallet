import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coin_cz/features/feature_flags/models/feature_flags_models.dart';
import 'package:coin_cz/features/feature_flags/services/feature_flags_service.dart';
import 'package:coin_cz/features/settings/region/region.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:coin_cz/features/shared/shared.dart';

final enabledServicesTypesProvider = AsyncNotifierProvider<
    EnabledServicesTypesNotifier,
    List<MarketplaceServiceAvailability>>(EnabledServicesTypesNotifier.new);

class EnabledServicesTypesNotifier
    extends AsyncNotifier<List<MarketplaceServiceAvailability>> {
  @override
  Future<List<MarketplaceServiceAvailability>> build() async {
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
    return tiles
        .map(MarketplaceServiceAvailability.fromResponse)
        .whereType<MarketplaceServiceAvailability>()
        .toList();
  }
}
