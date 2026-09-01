import 'package:aqua/features/settings/settings.dart';
import 'package:mocktail/mocktail.dart';

class MockManageAssetsProvider extends Mock implements ManageAssetsProvider {}

extension MockManageAssetsProviderX on MockManageAssetsProvider {
  void mockIsNonLbtcLiquidToLbtcCall({required bool value}) {
    when(() => isLiquidButNotLBTC(any())).thenReturn(value);
    when(() => isLBTC(any())).thenReturn(value);
  }

  void mockIsUsdtEnabledCall({required bool value}) {
    when(() => isUsdtEnabled).thenReturn(value);
  }

  void mockLiquidUsdtAssetCall({required Asset asset}) {
    when(() => liquidUsdtAsset).thenReturn(asset);
  }

  void mockDiscoveredAssets({required List<Asset> assets}) {
    when(() => discoveredAssets).thenReturn(assets);
  }

  void mockEnabledDiscoveredAssets({required List<Asset> assets}) {
    when(() => enabledDiscoveredAssets).thenReturn(assets);
  }
}
