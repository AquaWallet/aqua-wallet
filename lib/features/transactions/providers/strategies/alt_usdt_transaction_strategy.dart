import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';

final altUsdtTransactionUiModelsProvider = Provider.autoDispose((ref) {
  return AltUsdtTransactionUiModelCreator(
    ref: ref,
    formatter: ref.read(formatProvider),
    assetResolutionService: ref.read(assetResolutionServiceProvider),
    failureService: ref.read(txnFailureServiceProvider),
    confirmationService: ref.read(confirmationServiceProvider),
    appLocalizations: ref.read(appLocalizationsProvider),
  );
});

// Strategy for Alt USDt swap transactions (facilitated by Sideshift and Changelly)
//
// These are swaps between Liquid USDt and alternative USDt tokens on other chains
// (Ethereum, Tron, Binance, Solana, Polygon, TON).
//
// Rules:
// - Shows on BOTH asset pages (though we only have Liquid USDt as user asset)
// - Amount is negative on sending side, positive on receiving side
class AltUsdtTransactionUiModelCreator extends TransactionUiModelCreator {
  const AltUsdtTransactionUiModelCreator({
    required super.ref,
    required super.formatter,
    required super.assetResolutionService,
    required super.failureService,
    required super.confirmationService,
    required super.appLocalizations,
  });

  @override
  bool shouldShowTransactionForAsset(TransactionStrategyArgs args) {
    // Alt USDt transactions should only show on USDt pages, never on LBTC/BTC
    if (!args.asset.isAnyUsdt) {
      return false;
    }

    final dbTxn = args.dbTransaction;
    final networkTxn = args.networkTransaction;

    final pair = assetResolutionService.resolveSwapAssetsFromDb(
      dbTxn: dbTxn!,
      asset: args.asset,
      availableAssets: args.availableAssets,
      networkTxn: networkTxn,
    );

    if (pair.toAsset == null) {
      return false;
    }

    // Show if asset matches toAsset (receiving asset)
    // If fromAsset is null (viewing from receiving side), still show if toAsset matches
    if (args.asset.id == pair.toAsset!.id) {
      return true;
    }

    // Show if fromAsset is known and matches the viewing asset
    if (pair.fromAsset != null && args.asset.id == pair.fromAsset!.id) {
      return true;
    }

    return false;
  }

  @override
  String? getCryptoAmountForPending(TransactionStrategyArgs args) {
    final dbTxn = args.dbTransaction;
    final networkTxn = args.networkTransaction;

    if (dbTxn != null && dbTxn.ghostTxnAmount != null) {
      final isReceivingSide = dbTxn.assetId == args.asset.id;
      final amount = (dbTxn.ghostTxnAmount ?? 0) + (dbTxn.ghostTxnFee ?? 0);
      return formatter.signedFormatAssetAmount(
        amount: isReceivingSide ? amount : -amount,
        asset: args.asset,
        decimalPlacesOverride: kUsdtDisplayPrecision,
      );
    }

    if (networkTxn != null) {
      final amount = networkTxn.satoshi?[args.asset.id] as int;
      return formatter.signedFormatAssetAmount(
        amount: amount,
        asset: args.asset,
        decimalPlacesOverride: kUsdtDisplayPrecision,
      );
    }

    return null;
  }

  @override
  String? getCryptoAmountForNormal(TransactionStrategyArgs args) {
    final networkTxn = args.networkTransaction;
    if (networkTxn == null) {
      // No-op: Can not proceed without network transaction for confirmed txn
      return null;
    }

    final amount = networkTxn.satoshi?[args.asset.id] as int;
    return formatter.signedFormatAssetAmount(
      amount: amount,
      asset: args.asset,
      decimalPlacesOverride: kUsdtDisplayPrecision,
    );
  }

  @override
  Asset? getOtherAsset(TransactionStrategyArgs args) {
    final dbTxn = args.dbTransaction;
    final networkTxn = args.networkTransaction;

    if (dbTxn != null) {
      final resolved = assetResolutionService.resolveSwapAssetsFromDb(
        dbTxn: dbTxn,
        asset: args.asset,
        availableAssets: args.availableAssets,
        networkTxn: networkTxn,
      );
      return resolved.toAsset;
    }

    if (networkTxn != null) {
      final resolved = assetResolutionService.resolveSwapAssets(
        txn: networkTxn,
        asset: args.asset,
        availableAssets: args.availableAssets,
      );
      return resolved.toAsset;
    }

    return null;
  }

  @override
  TransactionUiModel? createPendingListItems(TransactionStrategyArgs args) {
    if (args.dbTransaction == null && args.networkTransaction == null) {
      // No-op: Need either db transaction or network transaction
      return null;
    }

    final createdAt = getCreatedAt(args);
    if (createdAt == null) {
      // No-op: Can not proceed without creation date
      return null;
    }

    final cryptoAmount = getCryptoAmountForPending(args);
    if (cryptoAmount == null) {
      // No-op: Can not proceed without crypto amount
      return null;
    }

    return TransactionUiModel.pending(
      createdAt: createdAt,
      cryptoAmount: cryptoAmount,
      asset: args.asset,
      otherAsset: getOtherAsset(args),
      dbTransaction: args.dbTransaction,
      transactionId:
          args.networkTransaction?.txhash ?? args.dbTransaction?.txhash,
    );
  }

  @override
  TransactionUiModel? createConfirmedListItems(TransactionStrategyArgs args) {
    if (args.networkTransaction == null) {
      // No-op: Can not proceed without network transaction
      return null;
    }

    final createdAt = getCreatedAt(args);
    if (createdAt == null) {
      // No-op: Can not proceed without creation date
      return null;
    }

    final cryptoAmount = getCryptoAmountForNormal(args);
    if (cryptoAmount == null) {
      // No-op: Can not proceed without crypto amount
      return null;
    }

    return TransactionUiModel.normal(
      createdAt: createdAt,
      cryptoAmount: cryptoAmount,
      asset: args.asset,
      otherAsset: getOtherAsset(args),
      transaction: args.networkTransaction!,
      dbTransaction: args.dbTransaction,
      isFailed: failureService.isFailed(args.dbTransaction),
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

    final feeAsset = getFeeAsset(args);
    final resolved = assetResolutionService.resolveSwapAssetsFromDb(
      dbTxn: dbTxn,
      asset: args.asset,
      availableAssets: args.availableAssets,
      networkTxn: args.networkTransaction,
    );
    final altUsdtAsset = resolved.toAsset;

    if (altUsdtAsset == null) {
      return null;
    }

    final date = dbTxn.ghostTxnCreatedAt?.formatFullDateTime ?? '';
    final amountSats = (dbTxn.ghostTxnAmount ?? 0) +
        (dbTxn.ghostTxnFee ??
            0); // Ghost TXN amount -> amount sent + Network fee ; Ghost TXN fee -> Swap fee
    final amount = formatter.formatAssetAmount(
      amount: -amountSats,
      asset: args.asset,
    );
    final amountFiat = convertToFiat(args.asset, -amountSats);

    final usdtSwapFee = await _calculateFeesFromDbOrder(
      dbTxn: dbTxn,
      feeAsset: feeAsset,
      networkTxn: args.networkTransaction,
    );

    final feeAmount = usdtSwapFee?.mapOrNull(
          usdtSwap: (fee) => fee.totalFeesCrypto,
        ) ??
        '';
    final isFailed = failureService.isFailed(dbTxn);

    return AssetTransactionDetailsUiModel.send(
      transactionId: dbTxn.txhash,
      date: date,
      confirmations: appLocalizations.pending,
      isPending: true,
      isFailed: isFailed,
      deliverAmount: amount,
      deliverAmountFiat: amountFiat,
      deliverAsset: altUsdtAsset,
      feeAmount: '',
      feeAmountFiat: feeAmount, // Only show the USDT amount, not the fiat value
      feeAsset: feeAsset,
      receiveAddress: dbTxn.receiveAddress,
      blindingUrl: computeBlindingUrl(args.networkTransaction, args.asset),
      canRbf: false,
      dbTransaction: dbTxn,
      isLightning: false,
    );
  }

  @override
  Future<AssetTransactionDetailsUiModel?> createConfirmedDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final networkTxn = args.networkTransaction;
    final dbTxn = args.dbTransaction;
    if (networkTxn == null || dbTxn == null) {
      return null;
    }

    if (networkTxn.type != GdkTransactionTypeEnum.outgoing) {
      return null;
    }

    final amountSats = networkTxn.satoshi?[args.asset.id] as int;
    final feeAsset = getFeeAsset(args);
    final resolved = _resolveSwapAssets(args);
    final altUsdtAsset = resolved.toAsset;

    if (altUsdtAsset == null) {
      //No-op: Alt USDt asset not found for outgoing transaction
      return null;
    }

    final confirmationCount = await confirmationService.getConfirmationCount(
      args.asset,
      args.networkTransaction?.blockHeight ?? 0,
    );
    final isPending = await confirmationService.isTransactionPending(
      transaction: args.networkTransaction!,
      asset: args.asset,
      dbTransaction: args.dbTransaction,
    );

    final amount = formatter.formatAssetAmount(
      amount: -amountSats,
      asset: args.asset,
    );

    final usdtSwapFee = await _calculateFeesFromDbOrder(
      dbTxn: dbTxn,
      feeAsset: feeAsset,
      networkTxn: networkTxn,
    );

    final feeAmount = usdtSwapFee?.mapOrNull(
          usdtSwap: (fee) => fee.totalFeesCrypto,
        ) ??
        '';
    final amountFiat = convertToFiat(args.asset, -amountSats);

    final isFailed = failureService.isFailed(args.dbTransaction);
    final confirmations = isPending
        ? appLocalizations.pending
        : formatter.formatConfirmations(
            appLocalizations,
            confirmationCount,
          );

    return AssetTransactionDetailsUiModel.send(
      transactionId: networkTxn.txhash ?? '',
      date: formatDate(networkTxn.createdAtTs),
      confirmations: confirmations,
      isPending: isPending,
      isFailed: isFailed,
      deliverAmount: amount,
      deliverAmountFiat: amountFiat,
      deliverAsset: altUsdtAsset,
      feeAmount: '',
      feeAmountFiat: feeAmount, // Only show the USDT amount, not the fiat value
      feeAsset: feeAsset,
      receiveAddress: args.dbTransaction?.receiveAddress ??
          networkTxn.outputs?.firstOrNull?.address,
      blindingUrl: computeBlindingUrl(args.networkTransaction, args.asset),
      notes: networkTxn.memo,
      canRbf: false,
      dbTransaction: args.dbTransaction,
      isLightning: false,
    );
  }

  SwapAssets _resolveSwapAssets(TransactionDetailsStrategyArgs args) {
    final dbTxn = args.dbTransaction;
    final networkTxn = args.networkTransaction;

    if (networkTxn != null &&
        networkTxn.swapOutgoingAssetId != null &&
        networkTxn.swapIncomingAssetId != null) {
      final isOnOutgoingPage = args.asset.id == networkTxn.swapOutgoingAssetId;
      final altUsdtAssetId = isOnOutgoingPage
          ? networkTxn.swapIncomingAssetId
          : networkTxn.swapOutgoingAssetId;

      if (altUsdtAssetId != null) {
        final found = args.availableAssets.firstWhereOrNull(
          (a) => a.id == altUsdtAssetId,
        );
        final altUsdtAsset = found ?? AssetUsdtExt.fromAssetId(altUsdtAssetId);
        return (
          fromAsset: isOnOutgoingPage ? args.asset : altUsdtAsset,
          toAsset: isOnOutgoingPage ? altUsdtAsset : args.asset,
        );
      }
    }

    if (dbTxn != null && dbTxn.assetId != null) {
      final found = args.availableAssets.firstWhereOrNull(
        (a) => a.id == dbTxn.assetId,
      );
      final altUsdtAsset = found ?? AssetUsdtExt.fromAssetId(dbTxn.assetId!);
      final isReceiving = dbTxn.assetId == args.asset.id;
      return (
        fromAsset: isReceiving ? altUsdtAsset : args.asset,
        toAsset: isReceiving ? args.asset : altUsdtAsset,
      );
    }

    return (fromAsset: null, toAsset: null);
  }

  Future<FeeStructure?> _calculateFeesFromDbOrder({
    required TransactionDbModel dbTxn,
    required Asset feeAsset,
    GdkTransaction? networkTxn,
  }) async {
    final orderId = dbTxn.serviceOrderId;
    if (orderId == null) {
      return null;
    }

    final orderDbModel = await ref.read(swapDBOrderProvider(orderId).future);
    if (orderDbModel == null) {
      return null;
    }

    final swapServiceSource = dbTxn.swapServiceSource;
    if (swapServiceSource == null) {
      return null;
    }

    final isUsdtFeeAsset = feeAsset.isAnyUsdt;

    // Calculate the actual fee based on fee asset type
    int? usdtFeeInSats;

    if (isUsdtFeeAsset) {
      if (networkTxn != null) {
        final sendingAsset = SwapAssetExt.fromId(orderDbModel.fromAsset);
        final sendingAssetId = sendingAsset.toAsset().id;
        final actualAmountSent = networkTxn.satoshi?[sendingAssetId];
        final intendedAmountSent = dbTxn.ghostTxnAmount;
        if (actualAmountSent != null && intendedAmountSent != null) {
          usdtFeeInSats = actualAmountSent.abs() - intendedAmountSent.abs();
        }
      }
    }

    final actualFeeInSats = dbTxn.estimatedFee;

    final depositAmount = Decimal.parse(orderDbModel.depositAmount);
    final settleAmount = orderDbModel.settleAmount != null
        ? Decimal.parse(orderDbModel.settleAmount!)
        : Decimal.zero;
    final settleCoinNetworkFee = orderDbModel.settleCoinNetworkFee != null
        ? Decimal.parse(orderDbModel.settleCoinNetworkFee!)
        : Decimal.zero;

    return ref.read(usdtSwapFeeCalculatorServiceProvider).calculateFeeStructure(
          swapServiceSource: swapServiceSource,
          depositAmount: depositAmount,
          settleAmount: settleAmount,
          settleCoinNetworkFee: settleCoinNetworkFee,
          sendNetworkFeeInSats: actualFeeInSats,
          isUsdtFeeAsset: isUsdtFeeAsset,
          usdtFeeInSats: usdtFeeInSats,
          btcUsdRateAtExecution: dbTxn.exchangeRateAtExecution,
        );
  }
}
