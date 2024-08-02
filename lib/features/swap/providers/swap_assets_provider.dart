import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

final swapAssetsProvider =
    ChangeNotifierProvider.autoDispose<SwapAssetsNotifier>(
        SwapAssetsNotifier.new);

class SwapAssetsNotifier extends ChangeNotifier {
  SwapAssetsNotifier(this.ref);

  final AutoDisposeRef ref;
  final List<Asset> assets = [];

  void addAssets(List<SideSwapAsset> swapAssets) {
    final allAssets = ref.watch(assetsProvider).asData?.value ?? [];

    assets.clear();

    final btcAsset = allAssets.firstWhereOrNull((asset) => asset.isBTC);
    if (btcAsset != null) {
      assets.add(btcAsset);
    }

    assets.addAll(allAssets
        .where((asset) => swapAssets.any((swap) => swap.assetId == asset.id)));

    // TODO removing EURx from the list. We will have to support it later.
    assets.removeWhere((item) => item.ticker == 'EURx');

    notifyListeners();
  }

  List<Asset> swappableAssets(Asset? asset) {
    if (asset == null) {
      return [];
    }

    final btcAsset = assets.firstWhere((asset) => asset.isBTC);
    final lbtcAsset = assets.firstWhere((asset) => asset.isLBTC);
    final usdtLiquidAsset = assets.firstWhereOrNull((asset) => asset
        .isUsdtLiquid); // usdt can be null if removed from managed assets by user

    if (asset.isBTC) {
      return [lbtcAsset];
    } else if (asset.isLBTC) {
      return usdtLiquidAsset != null ? [btcAsset, usdtLiquidAsset] : [btcAsset];
    } else if (asset.isUsdtLiquid) {
      return [lbtcAsset];
    }

    return [];
  }
}
