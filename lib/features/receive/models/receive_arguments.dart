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

  factory ReceiveArguments.fromAsset(Asset asset) => ReceiveArguments._(
        asset: asset,
        swapPair: asset.isAltUsdt
            ? SwapPair(
                from: SwapAsset.fromAsset(asset),
                to: SwapAssetExt.usdtLiquid,
              )
            : null,
      );
}
