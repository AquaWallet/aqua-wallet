import 'dart:convert';

import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/marketplace/api_services/marketplace_service.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:flutter/services.dart';

final availableRegionsProvider =
    FutureProvider.autoDispose<List<Region>>((ref) async {
  final keepAliveLink = ref.keepAlive();
  Future.delayed(const Duration(hours: 1), () => keepAliveLink.close());
  final marketPlaceService = ref.read(marketplaceServiceProvider);

  try {
    final fetchedRegionsResponse = await marketPlaceService.fetchRegions();
    final fetchedRegions = fetchedRegionsResponse.body?.regions;

    var validRegions = fetchedRegions != null && fetchedRegions.isNotEmpty;
    var isValidResponse = fetchedRegionsResponse.isSuccessful && validRegions;

    if (isValidResponse) {
      logger.info(
          '[availableRegionsProvider] Set regions: ${fetchedRegions.length}');
      return fetchedRegions;
    }
  } catch (e) {
    return await getStaticRegionsFn();
  }

  return await getStaticRegionsFn();
});

// This variable allows to override function call for testing.
Future<List<Region>> Function() getStaticRegionsFn = getStaticRegions;

Future<List<Region>> getStaticRegions() async {
  final staticRegionsJson =
      await json.decode(await rootBundle.loadString('assets/regions.json'));

  try {
    return RegionResponse.fromJson(staticRegionsJson).data!.regions;
  } catch (e) {
    throw Exception(
        'An error occurred while trying to fetch static regions json $e');
  }
}

final regionsProvider = Provider.autoDispose<RegionsProvider>((ref) {
  final prefs = ref.watch(prefsProvider);
  return RegionsProvider(ref, prefs);
});

class RegionsProvider extends ChangeNotifier {
  RegionsProvider(this.ref, this.prefs);

  final AutoDisposeProviderRef ref;
  final UserPreferencesNotifier prefs;

  Region? get currentRegion {
    final region = prefs.region;
    return region != null
        ? Region.fromJson(jsonDecode(region) as Map<String, dynamic>)
        : null;
  }

  bool get regionRequired => currentRegion == null;

  Future<void> setRegion(Region newRegion) async {
    final previousRegion = currentRegion;
    await updateRegionSpecificAssets(previousRegion, newRegion);
    prefs.setRegion(jsonEncode(newRegion.toJson()));
    notifyListeners();
  }

  Future<void> updateRegionSpecificAssets(
      Region? previousRegion, Region newRegion) async {
    final liquid = ref.read(liquidProvider);
    final prefs = ref.read(prefsProvider);

    // Handle MX region assets
    if (newRegion == RegionsStatic.mx && previousRegion != RegionsStatic.mx) {
      prefs.addAsset(liquid.mexasId);
    } else if (previousRegion == RegionsStatic.mx &&
        newRegion != RegionsStatic.mx) {
      await removeAssetIfZeroBalance(liquid.mexasId);
    }

    // Handle BR region assets
    if (newRegion == RegionsStatic.br && previousRegion != RegionsStatic.br) {
      prefs.addAsset(liquid.depixId);
    } else if (previousRegion == RegionsStatic.br &&
        newRegion != RegionsStatic.br) {
      await removeAssetIfZeroBalance(liquid.depixId);
    }
  }

  Future<void> removeAssetIfZeroBalance(String assetId) async {
    final asset = await ref.read(assetsProvider.future).then(
          (assets) => assets.firstWhereOrNull((a) => a.id == assetId),
        );
    if (asset != null) {
      final assetBalanceInSats =
          await ref.read(getBalanceProvider(asset).future);
      if (assetBalanceInSats == 0) {
        prefs.removeAsset(assetId);
      } else {
        logger.info('Asset $assetId not removed due to non-zero balance');
      }
    }
  }

  Future<void> setRegionRequired() async {
    prefs.removeRegion();
    notifyListeners();
  }
}
