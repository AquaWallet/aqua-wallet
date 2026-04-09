import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sideswapSwapTransactionUiModelsProvider = Provider.autoDispose((ref) {
  return SideswapSwapTransactionUiModelCreator(
    ref: ref,
    formatter: ref.read(formatProvider),
    assetResolutionService: ref.read(assetResolutionServiceProvider),
    failureService: ref.read(txnFailureServiceProvider),
    confirmationService: ref.read(confirmationServiceProvider),
    appLocalizations: ref.read(appLocalizationsProvider),
  );
});

// Strategy for Liquid to Liquid swap transactions facilitated by SideSwap
//
// Rules:
// - Shows on BOTH asset pages involved in the swap (from and to)
// - Amount is negative on sending side, positive on receiving side
class SideswapSwapTransactionUiModelCreator extends TransactionUiModelCreator {
  const SideswapSwapTransactionUiModelCreator({
    required super.ref,
    required super.formatter,
    required super.assetResolutionService,
    required super.failureService,
    required super.confirmationService,
    required super.appLocalizations,
  });

  @override
  bool shouldShowTransactionForAsset(TransactionStrategyArgs args) {
    final networkTxn = args.networkTransaction;
    final asset = args.asset;

    // Show only if current asset is involved in the swap
    if (networkTxn != null &&
        networkTxn.type == GdkTransactionTypeEnum.swap &&
        networkTxn.swapOutgoingAssetId != null &&
        networkTxn.swapIncomingAssetId != null) {
      return asset.id == networkTxn.swapOutgoingAssetId ||
          asset.id == networkTxn.swapIncomingAssetId;
    }

    // For pending swaps without network data, we need to resolve assets from DB
    // This happens when the transaction hasn't been broadcast yet
    final pair = _getAssetPairForSwap(args, args.dbTransaction, networkTxn);

    if (pair.toAsset == null) {
      return false;
    }

    // Show if asset matches toAsset (receiving asset)
    // If fromAsset is null (viewing from receiving side), still show if toAsset matches
    if (asset.id == pair.toAsset!.id) {
      return true;
    }

    // Show if fromAsset is known and matches the viewing asset
    if (pair.fromAsset != null && asset.id == pair.fromAsset!.id) {
      return true;
    }

    return false;
  }

  @override
  String? getCryptoAmountForPending(TransactionStrategyArgs args) {
    final dbTxn = args.dbTransaction;
    final networkTxn = args.networkTransaction;

    // Calculate cryptoAmount for display
    // - Receiving side: positive amount (what we receive)
    // - Sending side: negative amount (what we send)
    // - For sending side, prefer "delivered amount" (actual amount Sideswap received)
    if (dbTxn != null && dbTxn.ghostTxnAmount != null) {
      final pair = _getAssetPairForSwap(args, dbTxn, networkTxn);
      final isSendingSide = pair.fromAsset?.id == args.asset.id;
      final decimalOverride = args.asset.isUSDt ? kUsdtDisplayPrecision : null;

      // For sending side, use delivered amount if available
      // (actual amount Sideswap received, may differ from requested due to fees/slippage)
      final swapDeliveredAmount = dbTxn.ghostTxnSideswapDeliverAmount;
      if (isSendingSide && dbTxn.isSwap && swapDeliveredAmount != null) {
        return formatter.signedFormatAssetAmount(
          amount: -swapDeliveredAmount,
          asset: args.asset,
          decimalPlacesOverride: decimalOverride,
          removeTrailingZeros: false,
        );
      }

      // Use regular ghost transaction amount
      return formatter.signedFormatAssetAmount(
        amount: dbTxn.ghostTxnAmount!,
        asset: args.asset,
        decimalPlacesOverride: decimalOverride,
        removeTrailingZeros: false,
      );
    }

    // Fallback to network transaction
    if (networkTxn != null) {
      return formatter.signedFormatAssetAmount(
        amount: networkTxn.satoshi?[args.asset.id] as int,
        asset: args.asset,
        decimalPlacesOverride:
            args.asset.isNonSatsAsset ? kUsdtDisplayPrecision : null,
        removeTrailingZeros: false,
      );
    }

    return null;
  }

  @override
  String? getCryptoAmountForNormal(TransactionStrategyArgs args) {
    final networkTxn = args.networkTransaction;
    if (networkTxn == null || networkTxn.type != GdkTransactionTypeEnum.swap) {
      //No-op: Can not proceed without swap transaction
      return null;
    }

    final amount = networkTxn.satoshi?[args.asset.id] as int;
    return formatter.signedFormatAssetAmount(
      amount: amount,
      asset: args.asset,
      decimalPlacesOverride:
          args.asset.isNonSatsAsset ? kUsdtDisplayPrecision : null,
      removeTrailingZeros: false,
    );
  }

  @override
  Asset? getOtherAsset(TransactionStrategyArgs args) {
    final networkTxn = args.networkTransaction;

    // For confirmed swaps, use network transaction data
    if (networkTxn != null && networkTxn.type == GdkTransactionTypeEnum.swap) {
      final resolved = assetResolutionService.resolveSwapAssets(
        txn: networkTxn,
        asset: args.asset,
        availableAssets: args.availableAssets,
      );
      return resolved.toAsset;
    }

    // For pending swaps, resolve from DB
    final pair = _getAssetPairForSwap(args, args.dbTransaction, networkTxn);
    return pair.toAsset;
  }

  @override
  TransactionUiModel? createPendingListItems(TransactionStrategyArgs args) {
    if (args.dbTransaction == null && args.networkTransaction == null) {
      //No-op: Need either db transaction or network transaction
      return null;
    }

    final createdAt = getCreatedAt(args);
    if (createdAt == null) {
      //No-op: Can not proceed without creation date
      return null;
    }

    final cryptoAmount = getCryptoAmountForPending(args);
    if (cryptoAmount == null) {
      //No-op: Can not proceed without crypto amount
      return null;
    }

    // Get the actual from/to assets based on swap direction
    final assetPair = _getAssetPairForSwap(
      args,
      args.dbTransaction,
      args.networkTransaction,
    );

    // If fromAsset is null (viewing from receiving side), use the viewing asset
    // This happens when we can't determine the sending asset from DB alone
    final asset = assetPair.fromAsset ?? args.asset;
    final otherAsset =
        assetPair.fromAsset == null ? getOtherAsset(args) : assetPair.toAsset;

    return TransactionUiModel.pending(
      createdAt: createdAt,
      cryptoAmount: cryptoAmount,
      asset: asset,
      otherAsset: otherAsset,
      dbTransaction: args.dbTransaction,
      transactionId:
          args.networkTransaction?.txhash ?? args.dbTransaction?.txhash,
    );
  }

  SwapAssets _getAssetPairForSwap(
    TransactionStrategyArgs args,
    TransactionDbModel? dbTxn,
    GdkTransaction? networkTxn,
  ) {
    if (dbTxn != null) {
      return assetResolutionService.resolveSwapAssetsFromDb(
        dbTxn: dbTxn,
        asset: args.asset,
        availableAssets: args.availableAssets,
        networkTxn: networkTxn,
      );
    } else if (networkTxn != null) {
      // For network swaps, resolveSwapAssets returns the actual swap direction
      return assetResolutionService.resolveSwapAssets(
        txn: networkTxn,
        asset: args.asset,
        availableAssets: args.availableAssets,
      );
    } else {
      return (fromAsset: null, toAsset: null);
    }
  }

  @override
  TransactionUiModel? createConfirmedListItems(TransactionStrategyArgs args) {
    if (args.networkTransaction == null) return null;
    if (args.networkTransaction!.type != GdkTransactionTypeEnum.swap) {
      return null;
    }

    final createdAt = getCreatedAt(args);
    if (createdAt == null) {
      //No-op: Can not proceed without creation date
      return null;
    }

    final cryptoAmount = getCryptoAmountForNormal(args);
    if (cryptoAmount == null) {
      //No-op: Can not proceed without crypto amount
      return null;
    }

    final isFailed = failureService.isFailed(args.dbTransaction);

    // Get the actual from/to assets based on swap direction
    final assetPair = _getAssetPairForSwap(
      args,
      args.dbTransaction,
      args.networkTransaction,
    );

    return TransactionUiModel.normal(
      createdAt: createdAt,
      cryptoAmount: cryptoAmount,
      asset: assetPair.fromAsset!,
      otherAsset: assetPair.toAsset,
      transaction: args.networkTransaction!,
      dbTransaction: args.dbTransaction,
      isFailed: isFailed,
    );
  }

  @override
  Future<AssetTransactionDetailsUiModel?> createPendingDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final dbTxn = args.dbTransaction;
    if (dbTxn == null) {
      return null;
    }

    final feeAsset = args.availableAssets.firstWhere(
      (asset) => asset.id == dbTxn.feeAssetId,
      orElse: () => Asset.lbtc(),
    );
    final resolved = _resolveSwapAssets(args);
    final deliveredAsset = resolved.fromAsset;
    final receivedAsset = resolved.toAsset;

    if (deliveredAsset == null || receivedAsset == null) {
      //No-op: Need both delivered and received assets for swap
      return null;
    }

    final date = dbTxn.ghostTxnCreatedAt?.formatFullDateTime ?? '';
    final deliveredAmountSats = dbTxn.ghostTxnSideswapDeliverAmount ?? 0;
    final receivedAmountSats = dbTxn.ghostTxnAmount ?? 0;

    final deliveredAmount = formatter.formatAssetAmount(
      amount: deliveredAmountSats.abs(),
      asset: deliveredAsset,
      removeTrailingZeros: !deliveredAsset.isNonSatsAsset,
    );

    final receivedAmount = formatter.formatAssetAmount(
      amount: receivedAmountSats.abs(),
      asset: receivedAsset,
      removeTrailingZeros: !receivedAsset.isNonSatsAsset,
    );

    final feeAmountSats = dbTxn.ghostTxnFee ?? 0;
    final feeAmount = formatter.formatAssetAmount(
      amount: feeAmountSats,
      asset: feeAsset,
      removeTrailingZeros: !feeAsset.isNonSatsAsset,
    );

    final feeAmountFiat = convertToFiat(feeAsset, feeAmountSats);

    return AssetTransactionDetailsUiModel.swap(
      transactionId: dbTxn.txhash,
      date: date,
      confirmationCount: 0,
      isPending: true,
      deliverAsset: deliveredAsset,
      receiveAsset: receivedAsset,
      deliverAmount: deliveredAmount,
      receiveAmount: receivedAmount,
      feeAmount: feeAmount,
      feeAmountFiat: feeAmountFiat,
      feeAsset: feeAsset,
      depositAddress: dbTxn.serviceAddress ?? '',
      orderId: dbTxn.serviceOrderId ?? '',
      blindingUrl: '',
      dbTransaction: dbTxn,
      swapServiceName: dbTxn.swapServiceName ?? '',
      swapServiceUrl: dbTxn.swapServiceUrl ?? '',
    );
  }

  @override
  Future<AssetTransactionDetailsUiModel?> createConfirmedDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final networkTxn = args.networkTransaction;
    if (networkTxn == null || networkTxn.type != GdkTransactionTypeEnum.swap) {
      return null;
    }

    // Swap fees are always in L-BTC regardless of the asset being swapped.
    final feeAsset = Asset.lbtc();
    final confirmationCount = await confirmationService.getConfirmationCount(
      args.asset,
      networkTxn.blockHeight ?? 0,
    );
    final isPending = await confirmationService.isTransactionPending(
      transaction: networkTxn,
      asset: args.asset,
      dbTransaction: args.dbTransaction,
    );
    final deliveredAsset = args.availableAssets.firstWhereOrNull(
      (asset) => asset.id == networkTxn.swapOutgoingAssetId,
    );
    final receivedAsset = args.availableAssets.firstWhereOrNull(
      (asset) => asset.id == networkTxn.swapIncomingAssetId,
    );

    if (deliveredAsset == null || receivedAsset == null) {
      return null;
    }

    final deliveredAmountSats = networkTxn.swapOutgoingSatoshi as int;
    final deliveredAmount = formatter.formatAssetAmount(
      amount: deliveredAmountSats.abs(),
      asset: deliveredAsset,
      removeTrailingZeros: !deliveredAsset.isNonSatsAsset,
    );

    final receivedAmountSats = networkTxn.swapIncomingSatoshi as int;
    final receivedAmount = formatter.formatAssetAmount(
      amount: receivedAmountSats,
      asset: receivedAsset,
      removeTrailingZeros: !receivedAsset.isNonSatsAsset,
    );

    final feeAmountSats = networkTxn.fee ?? 0;
    final feeAmount = formatter.formatAssetAmount(
      amount: feeAmountSats,
      asset: feeAsset,
      removeTrailingZeros: !feeAsset.isNonSatsAsset,
    );

    final feeAmountFiat = convertToFiat(feeAsset, feeAmountSats);

    return AssetTransactionDetailsUiModel.swap(
      transactionId: networkTxn.txhash,
      date: formatDate(networkTxn.createdAtTs),
      confirmationCount: confirmationCount,
      isPending: isPending,
      notes: args.dbTransaction?.note ?? networkTxn.memo,
      deliverAsset: deliveredAsset,
      receiveAsset: receivedAsset,
      deliverAmount: deliveredAmount,
      receiveAmount: receivedAmount,
      feeAmount: feeAmount,
      feeAmountFiat: feeAmountFiat,
      feeAsset: feeAsset,
      depositAddress: networkTxn.outputs?.first.address ?? '',
      orderId: args.dbTransaction?.serviceOrderId ?? '',
      blindingUrl: computeBlindingUrl(args.networkTransaction, args.asset),
      dbTransaction: args.dbTransaction,
      swapServiceName: args.dbTransaction?.swapServiceName ?? '',
      swapServiceUrl: args.dbTransaction?.swapServiceUrl ?? '',
    );
  }

  SwapAssets _resolveSwapAssets(TransactionDetailsStrategyArgs args) {
    final dbTxn = args.dbTransaction;
    final networkTxn = args.networkTransaction;

    if (dbTxn != null) {
      return assetResolutionService.resolveSwapAssetsFromDb(
        dbTxn: dbTxn,
        asset: args.asset,
        availableAssets: args.availableAssets,
        networkTxn: networkTxn,
      );
    }

    if (networkTxn != null) {
      return assetResolutionService.resolveSwapAssets(
        txn: networkTxn,
        asset: args.asset,
        availableAssets: args.availableAssets,
      );
    }

    return (fromAsset: null, toAsset: null);
  }
}
