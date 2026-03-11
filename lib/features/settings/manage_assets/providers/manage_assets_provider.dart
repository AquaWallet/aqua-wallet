import 'dart:convert';

import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/marketplace/api_services/marketplace_service.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/iterable_ext.dart';
import 'package:async/async.dart';
import 'package:chopper/chopper.dart';
import 'package:flutter/services.dart';

Future<Result<List<Asset>>> fetchAssets(
    AutoDisposeFutureProviderRef ref) async {
  final env = ref.read(envProvider);
  final marketPlaceService = ref.read(marketplaceServiceProvider);

  Future<Response<AssetsResponse>> fetch() async {
    return switch (env) {
      Env.mainnet => marketPlaceService.fetchAssets(),
      Env.testnet || Env.regtest => marketPlaceService.fetchTestNetAssets(),
    };
  }

  try {
    final assetsResponse = await fetch();
    logger.info(
        '[ManageAssets] Fetched ${assetsResponse.body?.assets.length} assets');
    return Result.value(assetsResponse.bodyOrThrow.assets);
  } catch (e) {
    logger.warning('[ManageAssets] Failed to fetch assets');
    return Result.error(e);
  }
}

// This variable allows to override function call for testing.
Future<List<Asset>> Function(AutoDisposeFutureProviderRef<List<Asset>>)
    getStaticAssetFn = (ref) => getStaticAssets(ref);

Future<List<Asset>> getStaticAssets(
    AutoDisposeFutureProviderRef<List<Asset>> ref) async {
  final env = ref.watch(envProvider);

  final staticAssetsResource =
      env == Env.mainnet ? 'assets/assets.json' : 'assets/assets-testnet.json';

  final staticAssetsRaw = await rootBundle.loadString(staticAssetsResource);
  final staticAssetsJson = await json.decode(staticAssetsRaw);
  try {
    return AssetsResponse.fromJson(staticAssetsJson).data?.assets ?? [];
  } catch (e) {
    throw Exception(
        'An error occurred while trying to fetch static assets json $e');
  }
}

final availableAssetsProvider =
    FutureProvider.autoDispose<List<Asset>>((ref) async {
  final keepAliveLink = ref.keepAlive();
  Future.delayed(const Duration(hours: 1), () => keepAliveLink.close());

  final fetchedAssetsJson = await fetchAssets(ref);
  final response = fetchedAssetsJson.asValue?.value;
  final env = ref.watch(envProvider);

  final List<Asset> assetsResponse;
  if (response != null && response.isNotEmpty) {
    assetsResponse = response;
  } else {
    assetsResponse = await getStaticAssetFn(ref);
  }

  final allAssets = [
    ...assetsResponse.map((asset) => asset.copyWith(
          isLiquid: true,
          isLBTC: ref.read(liquidProvider).policyAsset == asset.id,
          isUSDt: ref.read(liquidProvider).usdtId == asset.id,
        )),
    if (env == Env.testnet) Asset.liquidTest(),
  ];

  // Add default assets to user assets
  if (ref.read(prefsProvider).userAssetIds.isEmpty) {
    allAssets
        .where((asset) => asset.isDefaultAsset)
        .forEach((asset) => ref.read(prefsProvider).addAsset(asset.id));

    // Add mexas if region mx
    final region = ref.watch(regionsProvider.select((p) => p.currentRegion));
    if (region != null) {
      if (region == RegionsStatic.mx) {
        ref.read(prefsProvider).addAsset(ref.read(liquidProvider).mexasId);
      }

      // Add depix if region br
      if (region == RegionsStatic.br) {
        ref.read(prefsProvider).addAsset(ref.read(liquidProvider).depixId);
      }
    }
  }

  return allAssets;
});

final manageAssetsProvider = Provider.autoDispose<ManageAssetsProvider>((ref) {
  final env = ref.watch(envProvider);
  final prefs = ref.watch(prefsProvider);
  final assets = ref.watch(availableAssetsProvider).asData?.value ?? [];
  return ManageAssetsProvider(env, prefs, assets);
});

class ManageAssetsProvider extends ChangeNotifier {
  ManageAssetsProvider(this.env, this.prefs, this.allAssets);

  final Env env;
  final UserPreferencesNotifier prefs;
  //NOTE - The assets supported by Aqua at a given moment (fetched from API)
  final List<Asset> allAssets;

  //NOTE - These are all the assets that are currently enabled by the user.
  //This is supposed to be a subset of [availableAssets].
  List<Asset> get userAssets {
    return prefs.userAssetIds
        .map((id) => allAssets.firstWhereOrNull((asset) => asset.id == id))
        .whereType<Asset>()
        .toList();
  }

  //NOTE - These are the assets available to the user for adding to their wallet
  //The list provided by the API is dependent on the GDK so there is no need to
  //verify if the assets are present in the GDK ([gdkAssets]) supported assets.
  List<Asset> get availableAssets => allAssets
      .whereNot((asset) => prefs.userAssetIds.contains(asset.id))
      .where((asset) => asset.isRemovable)
      .whereType<Asset>()
      .distinctBy((asset) => asset.id)
      .toList();

  Future<void> addAsset(Asset asset) async {
    prefs.addAsset(asset.id);
    notifyListeners();
  }

  Future<void> saveAssets(List<Asset> assets) async {
    prefs.addAllAssets(assets.map((asset) => asset.id).toList());
    notifyListeners();
  }

  Future<void> removeAsset(Asset asset) async {
    prefs.removeAsset(asset.id);
    notifyListeners();
  }

  Asset get btcAsset => Asset.btc();

  /// Convenience getter for `lbtc` asset
  Asset get lbtcAsset => allAssets.firstWhere((asset) => switch (env) {
        Env.mainnet => asset.ticker == "L-BTC",
        _ => asset.ticker == "tL-BTC",
      });

  Asset get liquidUsdtAsset =>
      allAssets.firstWhere((asset) => asset.ticker == "USDt");

  List<Asset> get mainTransactableAssets =>
      [btcAsset, Asset.lightning(), ...allAssets];

  /// Convenience getter for list of curated assets
  List<Asset> get curatedAssets {
    return [
      btcAsset,
      if (isUsdtEnabled) ...{
        liquidUsdtAsset,
      },
      Asset.lightning(),
      lbtcAsset,
      ...userAssets.where((asset) =>
          asset != liquidUsdtAsset &&
          asset !=
              lbtcAsset), // filter out usdt and liquid since they are already added
      if (env == Env.testnet) Asset.liquidTest()
    ];
  }

  /// Validate `asset` is a USDt asset
  bool isUsdt(Asset asset) => asset.isAnyUsdt;
  bool isLBTC(Asset asset) => asset.id == lbtcAsset.id;

  /// Validate `asset` is any active liquid asset
  bool isLiquid(Asset asset) {
    return [liquidUsdtAsset, lbtcAsset, ...userAssets]
        .any((a) => a.id == asset.id);
  }

  /// Validate `asset` is any active liquid asset EXCEPT ltbc
  bool isLiquidButNotLBTC(Asset asset) {
    return isLiquid(asset) && !isLBTC(asset);
  }

  // Convenience getter to check whether or not USDt is enabled
  bool get isUsdtEnabled => userAssets.any((asset) => asset.isUSDt);
}
