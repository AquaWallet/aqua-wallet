import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';
import 'package:aqua/features/swaps/models/swap_models_ext.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receive_arguments.freezed.dart';

@freezed
class ReceiveArguments with _$ReceiveArguments {
  const factory ReceiveArguments._({
    required Asset asset,
    SwapPair? swapPair,
  }) = _ReceiveArguments;

  factory ReceiveArguments.btc(Asset asset) => ReceiveArguments._(
        asset: asset,
        swapPair: null,
      );

  factory ReceiveArguments.lbtc(Asset asset) => ReceiveArguments._(
        asset: asset,
        swapPair: null,
      );

  factory ReceiveArguments.liquidUsdt(Asset asset) => ReceiveArguments._(
        asset: asset,
        swapPair: null,
      );

  factory ReceiveArguments.ethereumUsdt(Asset asset) => ReceiveArguments._(
        asset: asset,
        swapPair: SwapPair(
          from: SwapAssetExt.usdtLiquid,
          to: SwapAssetExt.usdtEth,
        ),
      );

  factory ReceiveArguments.tronUsdt(Asset asset) => ReceiveArguments._(
        asset: asset,
        swapPair: SwapPair(
          from: SwapAssetExt.usdtLiquid,
          to: SwapAssetExt.usdtTrx,
        ),
      );

  factory ReceiveArguments.binanceUsdt(Asset asset) => ReceiveArguments._(
        asset: asset,
        swapPair: SwapPair(
          from: SwapAssetExt.usdtLiquid,
          to: SwapAssetExt.usdtBep,
        ),
      );

  factory ReceiveArguments.solanaUsdt(Asset asset) => ReceiveArguments._(
        asset: asset,
        swapPair: SwapPair(
          from: SwapAssetExt.usdtLiquid,
          to: SwapAssetExt.usdtSol,
        ),
      );

  factory ReceiveArguments.polygonUsdt(Asset asset) => ReceiveArguments._(
        asset: asset,
        swapPair: SwapPair(
          from: SwapAssetExt.usdtLiquid,
          to: SwapAssetExt.usdtPol,
        ),
      );

  factory ReceiveArguments.tonUsdt(Asset asset) => ReceiveArguments._(
        asset: asset,
        swapPair: SwapPair(
          from: SwapAssetExt.usdtLiquid,
          to: SwapAssetExt.usdtTon,
        ),
      );

  factory ReceiveArguments.fromAsset(Asset asset) {
    if (asset.isLBTC) {
      return ReceiveArguments.lbtc(asset);
    }
    if (asset.isUsdtLiquid) {
      return ReceiveArguments.liquidUsdt(asset);
    }
    switch (asset.id) {
      case AssetIds.btc:
        return ReceiveArguments.btc(asset);
      case AssetIds.usdtEth:
        return ReceiveArguments.ethereumUsdt(asset);
      case AssetIds.usdtTrx:
        return ReceiveArguments.tronUsdt(asset);
      case AssetIds.usdtBep:
        return ReceiveArguments.binanceUsdt(asset);
      case AssetIds.usdtSol:
        return ReceiveArguments.solanaUsdt(asset);
      case AssetIds.usdtPol:
        return ReceiveArguments.polygonUsdt(asset);
      case AssetIds.usdtTon:
        return ReceiveArguments.tonUsdt(asset);
      default:
        return ReceiveArguments.liquidUsdt(asset);
    }
  }
}
