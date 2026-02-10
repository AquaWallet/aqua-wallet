import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef SwapAssets = ({Asset? fromAsset, Asset? toAsset});

final assetResolutionServiceProvider =
    Provider.autoDispose((_) => const AssetResolutionService());

// Handles asset resolution for swaps and special cases
//
// This service manages the complexity of determining which assets are involved
// in swap transactions, handling the directionality and asset mapping.
class AssetResolutionService {
  const AssetResolutionService();

  // Resolves swap assets from network transaction data
  SwapAssets resolveSwapAssets({
    required GdkTransaction txn,
    required Asset asset,
    required List<Asset> availableAssets,
  }) {
    if (txn.type != GdkTransactionTypeEnum.swap) {
      throw AssetTransactionsInvalidTypeException();
    }

    final fromAsset = _findOrCreateAsset(
      txn.swapOutgoingAssetId,
      availableAssets,
    );
    final toAsset = _findOrCreateAsset(
      txn.swapIncomingAssetId,
      availableAssets,
    );

    return (fromAsset: fromAsset, toAsset: toAsset);
  }

  SwapAssets resolveSwapAssetsFromDb({
    required TransactionDbModel dbTxn,
    required Asset asset,
    required List<Asset> availableAssets,
    GdkTransaction? networkTxn,
  }) {
    if (!dbTxn.isAnySwap) {
      return (fromAsset: asset, toAsset: null);
    }

    final resolved = _resolveSwapAssetsFromData(
      dbTxn: dbTxn,
      asset: asset,
      availableAssets: availableAssets,
      networkTxn: networkTxn,
    );

    return (fromAsset: resolved.fromAsset, toAsset: resolved.toAsset);
  }

  // Private Helper Methods

  Asset? _findAssetById(String? assetId, List<Asset> availableAssets) {
    if (assetId == null) return null;
    return availableAssets.firstWhereOrNull((a) => a.id == assetId);
  }

  // Resolves swap assets from either network transaction or database
  SwapAssets _resolveSwapAssetsFromData({
    required TransactionDbModel dbTxn,
    required Asset asset,
    required List<Asset> availableAssets,
    GdkTransaction? networkTxn,
  }) {
    final hasCompleteSwapData = networkTxn != null &&
        networkTxn.swapOutgoingAssetId != null &&
        networkTxn.swapIncomingAssetId != null;

    // Prefer network transaction data if available
    if (hasCompleteSwapData) {
      final fromAsset = _findOrCreateAsset(
        networkTxn.swapOutgoingAssetId,
        availableAssets,
      );
      final toAsset = _findOrCreateAsset(
        networkTxn.swapIncomingAssetId,
        availableAssets,
      );

      return (fromAsset: fromAsset, toAsset: toAsset);
    }

    // Fallback to database transaction data
    final receivingAsset = _findOrCreateAsset(dbTxn.assetId, availableAssets);

    // For pegs, determine direction from transaction type, not viewing asset
    if (dbTxn.type == TransactionDbModelType.sideswapPegIn) {
      return (fromAsset: Asset.btc(), toAsset: Asset.lbtc());
    }
    if (dbTxn.type == TransactionDbModelType.sideswapPegOut) {
      return (fromAsset: Asset.lbtc(), toAsset: Asset.btc());
    }

    // For sideswapSwap, assetId is the receiving asset
    // If viewing from an asset that's not the receiving asset, that asset is the sending asset
    if (dbTxn.type == TransactionDbModelType.sideswapSwap) {
      final isViewingFromReceivingSide =
          receivingAsset != null && asset.id == receivingAsset.id;
      // If viewing from receiving side, we can't determine the sending asset from DB alone
      // Return null for fromAsset to indicate we don't know the direction
      final fromAsset = isViewingFromReceivingSide ? null : asset;
      final toAsset = receivingAsset;
      return (fromAsset: fromAsset, toAsset: toAsset);
    }

    final otherAsset = _getOtherAssetForType(
      dbTxn.type,
      receivingAsset,
      asset,
      availableAssets,
    );

    // For sideshiftSwap, if viewing from an asset that's not the receiving asset,
    // that asset is the sending asset
    if (dbTxn.type == TransactionDbModelType.sideshiftSwap) {
      final isViewingFromReceivingSide =
          receivingAsset != null && asset.id == receivingAsset.id;
      final fromAsset = isViewingFromReceivingSide ? null : asset;
      final toAsset = receivingAsset;
      return (fromAsset: fromAsset, toAsset: toAsset);
    }

    final fromAsset = receivingAsset;
    final toAsset = otherAsset;

    return (fromAsset: fromAsset, toAsset: toAsset);
  }

  Asset? _findOrCreateAsset(String? assetId, List<Asset> availableAssets) {
    if (assetId == null) return null;

    final found = availableAssets.firstWhereOrNull((a) => a.id == assetId);
    if (found != null) {
      return found;
    }

    // The Alt USDt assets are expected to be absent from our local asset list.
    //So if an asset isn't found there, we assume that it's an Alt USDt.
    return AssetUsdtExt.fromAssetId(assetId);
  }

  // Gets the counterparty asset based on transaction type
  Asset? _getOtherAssetForType(
    TransactionDbModelType? type,
    Asset? receivingAsset,
    Asset currentAsset,
    List<Asset> availableAssets,
  ) {
    return switch (type) {
      // Reverse swaps and peg-ins receive LBTC
      TransactionDbModelType.boltzReverseSwap ||
      TransactionDbModelType.sideswapPegIn =>
        Asset.lbtc(),
      // Normal swaps and peg-outs send to BTC
      TransactionDbModelType.sideswapPegOut ||
      TransactionDbModelType.boltzSwap =>
        Asset.btc(),
      // Sideshift swaps (alt-USDT): use receiving asset if it's alt-USDT
      // If current asset is alt-USDT, the other side is Liquid USDT
      // Otherwise default to BTC (for legacy swaps)
      TransactionDbModelType.sideshiftSwap => receivingAsset?.isAltUsdt == true
          ? receivingAsset
          : (currentAsset.isAltUsdt
              ? availableAssets.firstWhereOrNull((a) => a.isUsdtLiquid) ??
                  Asset.usdtLiquid()
              : Asset.btc()),
      // Sideswap swaps use the receiving asset as the other asset
      TransactionDbModelType.sideswapSwap => receivingAsset,
      _ => null,
    };
  }
}
