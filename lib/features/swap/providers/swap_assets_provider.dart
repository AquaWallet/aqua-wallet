import 'package:aqua/data/data.dart';
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

    // TODO: removing mexas from the list for now since no liquidity. Add later when market confirmed.
    assets.removeWhere((item) => item.ticker == 'MEX');

    notifyListeners();
  }

  bool isSwappable(Asset deliverAsset, Asset settleAsset) {
    final swappable = swappableAssets(deliverAsset);
    return swappable.contains(settleAsset);
  }

  List<Asset> swappableAssets(Asset? asset) {
    if (asset == null) {
      return [];
    }

    final liquid = ref.read(liquidProvider);

    final btcAsset = assets.firstWhereOrNull((asset) => asset.isBTC);
    final lbtcAsset = assets.firstWhereOrNull((asset) => asset.isLBTC);
    final depixAsset =
        assets.firstWhereOrNull((asset) => asset.id == liquid.depixId);
    final eurXAsset =
        assets.firstWhereOrNull((asset) => asset.id == liquid.eurXId);
    final mexasAsset =
        assets.firstWhereOrNull((asset) => asset.id == liquid.mexasId);
    final usdtLiquidAsset =
        assets.firstWhereOrNull((asset) => asset.isUsdtLiquid);

    return switch (asset.id) {
      _ when (asset.isBTC) => [lbtcAsset!],
      _ when (asset.isLBTC) => [
          btcAsset!,
          if (usdtLiquidAsset != null) usdtLiquidAsset,
          if (depixAsset != null) depixAsset,
          if (eurXAsset != null) eurXAsset,
          if (mexasAsset != null) mexasAsset,
        ],
      _ when (asset.isUsdtLiquid) => [lbtcAsset!],
      _ when (asset.id == liquid.depixId || asset.id == liquid.eurXId) => [
          lbtcAsset!
        ],
      _ => [],
    };
  }
}
