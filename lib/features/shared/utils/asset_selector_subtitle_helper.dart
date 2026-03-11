import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

extension AssetUiModelSelectorSubtitle on AssetUiModel {
  String getSelectorSubtitle(
    BuildContext context,
    AquaAssetSelectorType type,
  ) {
    return switch (assetId) {
      AssetIds.btc => context.loc.onChain,
      AssetIds.lightning when (type == AquaAssetSelectorType.send) =>
        context.loc.assetTransactionsTypeSwapFrom('L-$subtitle'),
      AssetIds.lightning when (type == AquaAssetSelectorType.receive) =>
        context.loc.assetTransactionsTypeSwapTo('L-$subtitle'),
      _ when (AssetIds.usdtliquid.contains(assetId)) => "",
      _ when (AssetIds.lbtc.contains(assetId)) => context.loc.lBtc,
      _
          when (type == AquaAssetSelectorType.receive) &&
              AssetIds.isAnyUsdt(assetId) =>
        context.loc.swappedToLusdt,
      _ when (AssetIds.isAnyUsdt(assetId)) => context.loc.swappedFromLusdt,
      _ => "",
    };
  }
}

extension AssetSelectorMapExtension on Map<AssetUiModel, List<AssetUiModel>> {
  Map<AssetUiModel, List<AssetUiModel>> withSelectorSubtitles(
    BuildContext context,
    AquaAssetSelectorType type,
  ) {
    return map(
      (key, value) => MapEntry(
        key.copyWith(
          subtitle: key.getSelectorSubtitle(context, type),
        ),
        value
            .map(
              (asset) => asset.copyWith(
                subtitle: asset.getSelectorSubtitle(context, type),
              ),
            )
            .toList(),
      ),
    );
  }
}
