import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/swaps/swaps.dart';

import 'sideshift_assets.dart';

extension SideshiftAssetSwapExt on SideshiftAsset {
  SwapAsset toSwapAsset() {
    String swapAssetId = id;

    // Special handling for LBTC and USDT Liquid
    if (id == 'btc' && network == 'liquid') {
      swapAssetId =
          AssetIds.getAssetId(AssetType.lbtc, LiquidNetworkEnumType.mainnet);
    } else if (id == 'usdt' && network == 'liquid') {
      swapAssetId = AssetIds.getAssetId(
          AssetType.usdtliquid, LiquidNetworkEnumType.mainnet);
    }

    return SwapAsset(
      id: swapAssetId,
      name: name,
      ticker: coin,
    );
  }

  static SideshiftAsset fromSwapAsset(SwapAsset swapAsset) {
    final network = SideshiftAssetExt.getNetworkString(swapAsset.id);

    // Special handling for LBTC and USDT Liquid
    String sideshiftId = swapAsset.id;
    if (swapAsset.id ==
        AssetIds.getAssetId(AssetType.lbtc, LiquidNetworkEnumType.mainnet)) {
      sideshiftId = 'btc';
    } else if (swapAsset.id ==
        AssetIds.getAssetId(
            AssetType.usdtliquid, LiquidNetworkEnumType.mainnet)) {
      sideshiftId = 'usdt';
    }

    return SideshiftAsset(
      id: sideshiftId,
      coin: swapAsset.ticker,
      network: network,
      name: swapAsset.name,
    );
  }
}
