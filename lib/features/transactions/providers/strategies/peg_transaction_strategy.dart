import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pegTransactionUiModelsProvider = Provider.autoDispose((ref) {
  return PegTransactionUiModelCreator(
    ref: ref,
    formatter: ref.read(formatProvider),
    assetResolutionService: ref.read(assetResolutionServiceProvider),
    failureService: ref.read(txnFailureServiceProvider),
    confirmationService: ref.read(confirmationServiceProvider),
    appLocalizations: ref.read(appLocalizationsProvider),
  );
});

// Strategy for peg transactions facilitated by SideSwap (BTC <-> L-BTC)
//
// Rules:
// - Peg-in (BTC->LBTC): Shows on BOTH BTC and LBTC pages
// - Peg-out (LBTC->BTC): Shows on BOTH LBTC and BTC pages
// - Amount is always positive (receiving perspective)
// - The confirmed transaction on the receving side shows up as a normal receive
//transaction instead of an incoming Swap due to a limitation with the Sideswap
//funding transactions (Ref: https://github.com/jan3dev/aqua-dev/issues/2650)
class PegTransactionUiModelCreator extends TransactionUiModelCreator {
  const PegTransactionUiModelCreator({
    required super.ref,
    required super.formatter,
    required super.assetResolutionService,
    required super.failureService,
    required super.confirmationService,
    required super.appLocalizations,
  });

  @override
  bool shouldShowTransactionForAsset(TransactionStrategyArgs args) {
    return args.asset.isBTC || args.asset.isLBTC;
  }

  @override
  String? getCryptoAmountForPending(TransactionStrategyArgs args) {
    final dbTxn = args.dbTransaction;
    final networkTxn = args.networkTransaction;

    if (dbTxn == null && networkTxn == null) {
      // No-op: Can not proceed without either db or network transaction
      return null;
    }

    // Prefer network txn amount when available as it includes fees and has
    //correct sign, use ghostTxnAmount only as a fallback
    final dbTxnAmount =
        dbTxn != null ? -(dbTxn.ghostTxnAmount?.abs() ?? 0) : null;
    final amount = networkTxn?.satoshi?[args.asset.id] ?? dbTxnAmount;

    if (amount == null) return null;

    return formatter.signedFormatAssetAmount(
      amount: amount,
      asset: args.asset,
    );
  }

  @override
  String? getCryptoAmountForNormal(TransactionStrategyArgs args) {
    final networkTxn = args.networkTransaction;
    if (networkTxn == null) {
      // No-op: Can not proceed without network transaction for confirmed txn
      return null;
    }

    return formatter.signedFormatAssetAmount(
      amount: networkTxn.satoshi?[args.asset.id] as int,
      asset: args.asset,
    );
  }

  @override
  Asset? getOtherAsset(TransactionStrategyArgs args) {
    final dbTxn = args.dbTransaction;

    if (dbTxn == null) {
      // No-op: Can not proceed without db transaction
      return null;
    }

    return dbTxn.isPegIn ? Asset.lbtc() : Asset.btc();
  }

  @override
  TransactionUiModel? createPendingListItems(TransactionStrategyArgs args) {
    if (args.dbTransaction == null) {
      // No-op: Need db transaction to proceed
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

    final fromAsset = args.dbTransaction!.isPegIn ? Asset.btc() : Asset.lbtc();

    // For pending peg transactions, prefer the network transaction hash if available
    // (e.g., for peg-out incoming BTC that's pending confirmations)
    final transactionId =
        args.networkTransaction?.txhash ?? args.dbTransaction!.txhash;

    return TransactionUiModel.pending(
      createdAt: createdAt,
      cryptoAmount: cryptoAmount,
      asset: fromAsset,
      dbTransaction: args.dbTransaction,
      transactionId: transactionId,
      otherAsset: getOtherAsset(args),
    );
  }

  @override
  TransactionUiModel? createConfirmedListItems(TransactionStrategyArgs args) {
    if (args.networkTransaction == null || args.dbTransaction == null) {
      // No-op: Need both network transaction and db metadata
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

    final fromAsset = args.dbTransaction!.isPegIn ? Asset.btc() : Asset.lbtc();

    return TransactionUiModel.normal(
      createdAt: createdAt,
      cryptoAmount: cryptoAmount,
      asset: fromAsset,
      dbTransaction: args.dbTransaction,
      transaction: args.networkTransaction!,
      otherAsset: getOtherAsset(args),
      fiatAsset: args.asset,
      isFailed: failureService.isFailed(args.dbTransaction),
    );
  }

  @override
  Future<AssetTransactionDetailsUiModel?> createPendingDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final dbTxn = args.dbTransaction;
    if (dbTxn == null || !dbTxn.isPeg) {
      return null;
    }

    final date = dbTxn.ghostTxnCreatedAt?.formatFullDateTime ?? '';

    final isPegIn = dbTxn.isPegIn;
    final deliverAsset = isPegIn ? Asset.btc() : Asset.lbtc();
    final receiveAsset = isPegIn ? Asset.lbtc() : Asset.btc();
    final feeAsset = deliverAsset;

    final sendNetworkTxns =
        await ref.read(networkTransactionsProvider(deliverAsset).future);
    final receiveNetworkTxns =
        await ref.read(networkTransactionsProvider(receiveAsset).future);

    final (:sendTxn, :receiveTxn) =
        ref.read(pegSwapMatcherProvider).lookupPegSides(
              pegOrder: dbTxn,
              sendNetworkTxns: sendNetworkTxns,
              receiveNetworkTxns: receiveNetworkTxns,
            );

    final sendAmountSats = sendTxn?.satoshi?[deliverAsset.id]?.abs() ?? 0;
    final receiveAmountSats = receiveTxn?.satoshi?[receiveAsset.id]?.abs() ?? 0;

    final grossSendAmount = sendAmountSats > 0
        ? sendAmountSats
        : (dbTxn.ghostTxnAmount?.abs() ?? 0);

    final (:receiveAmountValue, :totalFee, isEstimated: _) =
        _calculateReceiveAndFee(
      grossSendAmount: grossSendAmount,
      receiveAmountSats: receiveAmountSats,
      isPegIn: isPegIn,
    );

    final deliverAmount = formatter.formatAssetAmount(
      amount: grossSendAmount,
      asset: deliverAsset,
      decimalPlacesOverride: null,
    );

    final receiveAmount = formatter.formatAssetAmount(
      amount: receiveAmountValue,
      asset: receiveAsset,
      decimalPlacesOverride: null,
    );

    final feeAmount = formatter.formatAssetAmount(
      amount: totalFee,
      asset: feeAsset,
    );

    final feeAmountFiat = convertToFiat(feeAsset, totalFee);

    final (:transactionId, :explorerAsset) = getPegExplorerInfo(
      viewingAsset: args.asset,
      deliverAsset: deliverAsset,
      receiveAsset: receiveAsset,
      sendTxn: sendTxn,
      receiveTxn: receiveTxn,
      fallbackTxHash: dbTxn.txhash,
    );

    // Note: Receive amount and fee amount are approximate.
    return AssetTransactionDetailsUiModel.peg(
      transactionId: transactionId,
      date: date,
      confirmationCount: 0,
      isPending: true,
      deliverAsset: deliverAsset,
      receiveAsset: receiveAsset,
      deliverAmount: deliverAmount,
      receiveAmount: '~$receiveAmount',
      feeAmount: '~$feeAmount',
      feeAmountFiat: feeAmountFiat,
      feeAsset: feeAsset,
      depositAddress: dbTxn.serviceAddress ?? '',
      orderId: dbTxn.serviceOrderId ?? '',
      blindingUrl: '',
      dbTransaction: dbTxn,
      swapServiceName: dbTxn.swapServiceName ?? '',
      swapServiceUrl: dbTxn.swapServiceUrl ?? '',
      explorerAsset: explorerAsset,
    );
  }

  @override
  Future<AssetTransactionDetailsUiModel?> createConfirmedDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final networkTxn = args.networkTransaction;
    final dbTxn = args.dbTransaction;

    if (networkTxn == null || dbTxn == null || !dbTxn.isPeg) {
      return null;
    }

    final isPegIn = dbTxn.isPegIn;
    final deliverAsset = isPegIn ? Asset.btc() : Asset.lbtc();
    final receiveAsset = isPegIn ? Asset.lbtc() : Asset.btc();

    final sendNetworkTxns =
        await ref.read(networkTransactionsProvider(deliverAsset).future);
    final receiveNetworkTxns =
        await ref.read(networkTransactionsProvider(receiveAsset).future);

    final (:sendTxn, :receiveTxn) =
        ref.read(pegSwapMatcherProvider).lookupPegSides(
              pegOrder: dbTxn,
              sendNetworkTxns: sendNetworkTxns,
              receiveNetworkTxns: receiveNetworkTxns,
            );

    // Calculate amounts from both sides
    final sendAmountSats = sendTxn?.satoshi?[deliverAsset.id]?.abs() ?? 0;
    final receiveAmountSats = receiveTxn?.satoshi?[receiveAsset.id]?.abs() ?? 0;

    // Gross send = what user sent
    final grossSendAmount = sendAmountSats > 0
        ? sendAmountSats
        : (dbTxn.ghostTxnAmount?.abs() ?? 0);

    final (:receiveAmountValue, :totalFee, :isEstimated) =
        _calculateReceiveAndFee(
      grossSendAmount: grossSendAmount,
      receiveAmountSats: receiveAmountSats,
      isPegIn: isPegIn,
    );

    final feeAsset = deliverAsset;
    final confirmationCount = await confirmationService.getConfirmationCount(
      args.asset,
      networkTxn.blockHeight ?? 0,
    );
    final isPending = await confirmationService.isTransactionPending(
      transaction: networkTxn,
      dbTransaction: dbTxn,
      asset: args.asset,
    );

    final deliverAmount = formatter.formatAssetAmount(
      amount: grossSendAmount,
      asset: deliverAsset,
      decimalPlacesOverride: null,
    );

    final receiveAmount = formatter.formatAssetAmount(
      amount: receiveAmountValue,
      asset: receiveAsset,
      decimalPlacesOverride: null,
    );

    final feeAmount = formatter.formatAssetAmount(
      amount: totalFee,
      asset: feeAsset,
    );

    final feeAmountFiat = convertToFiat(feeAsset, totalFee);

    final (:transactionId, :explorerAsset) = getPegExplorerInfo(
      viewingAsset: args.asset,
      deliverAsset: deliverAsset,
      receiveAsset: receiveAsset,
      sendTxn: sendTxn,
      receiveTxn: receiveTxn,
      fallbackTxHash: networkTxn.txhash,
    );

    final showApproximate = isPending || isEstimated;

    return AssetTransactionDetailsUiModel.peg(
      transactionId: transactionId,
      date: formatDate(networkTxn.createdAtTs),
      confirmationCount: confirmationCount,
      isPending: isPending,
      notes: args.dbTransaction?.note ?? networkTxn.memo,
      deliverAmount: deliverAmount,
      receiveAmount: showApproximate ? '~$receiveAmount' : receiveAmount,
      deliverAsset: deliverAsset,
      receiveAsset: receiveAsset,
      feeAmount: showApproximate ? '~$feeAmount' : feeAmount,
      feeAmountFiat: feeAmountFiat,
      feeAsset: feeAsset,
      depositAddress: networkTxn.outputs?.first.address ?? '',
      orderId: dbTxn.serviceOrderId ?? '',
      blindingUrl: computeBlindingUrl(args.networkTransaction, args.asset),
      swapServiceName: dbTxn.swapServiceName ?? '',
      swapServiceUrl: dbTxn.swapServiceUrl ?? '',
      dbTransaction: dbTxn,
      explorerAsset: explorerAsset,
    );
  }

  /// Calculates receive amount and total fee for peg transactions.
  ///
  /// Returns a record with:
  /// - `receiveAmountValue`: The amount user receives after fees
  /// - `totalFee`: The total fee (service fee + network fees)
  /// - `isEstimated`: Whether values are estimated (true) or from actual network data (false)
  ///
  /// Priority:
  /// 1. If `receiveAmountSats > 0` (from matched network transaction): Use actual values
  /// 2. Otherwise: Estimate using Sideswap's fee formula (0.1% service fee + second chain fee)
  ///
  /// Note: `ghostTxnFee` is always null for peg transactions (only set for LBTC↔USDt swaps),
  /// so we rely entirely on either matching the receive-side network transaction or estimating.
  ///
  /// The estimation fallback applies a minimum 0.1% fee to ensure `deliverAmount != receiveAmount`,
  /// preventing confusing UI where both amounts appear identical (which would imply zero fees).
  ({int receiveAmountValue, int totalFee, bool isEstimated})
      _calculateReceiveAndFee({
    required int grossSendAmount,
    required int receiveAmountSats,
    required bool isPegIn,
  }) {
    if (receiveAmountSats > 0) {
      final totalFee = grossSendAmount - receiveAmountSats;
      return (
        receiveAmountValue: receiveAmountSats,
        totalFee: totalFee > 0 ? totalFee : 0,
        isEstimated: false,
      );
    }

    final statusStream = ref.read(sideswapStatusStreamResultStateProvider);
    final feeRate = isPegIn
        ? ref.read(feeEstimateProvider).getLiquidFeeRate()
        : bitcoinFallbackFeeRate;
    final estimatedReceive =
        SideSwapFeeCalculator.subtractSideSwapFeeForPegDeliverAmount(
      grossSendAmount,
      isPegIn,
      statusStream,
      feeRate,
    );

    final estimatedFee = grossSendAmount - estimatedReceive;

    if (estimatedReceive > 0 && estimatedFee > 0) {
      return (
        receiveAmountValue: estimatedReceive,
        totalFee: estimatedFee,
        isEstimated: true,
      );
    }

    final minFee = (grossSendAmount * 0.001).ceil();
    final minReceive = grossSendAmount - minFee;

    return (
      receiveAmountValue: minReceive,
      totalFee: minFee,
      isEstimated: true,
    );
  }
}

typedef PegExplorerInfo = ({String transactionId, Asset explorerAsset});

@visibleForTesting
PegExplorerInfo getPegExplorerInfo({
  required Asset viewingAsset,
  required Asset deliverAsset,
  required Asset receiveAsset,
  required GdkTransaction? sendTxn,
  required GdkTransaction? receiveTxn,
  required String fallbackTxHash,
}) {
  final isViewingDeliverSide = viewingAsset.id == deliverAsset.id;

  if (isViewingDeliverSide && sendTxn?.txhash != null) {
    return (transactionId: sendTxn!.txhash, explorerAsset: deliverAsset);
  }

  if (!isViewingDeliverSide && receiveTxn?.txhash != null) {
    return (transactionId: receiveTxn!.txhash, explorerAsset: receiveAsset);
  }

  // Fallback 1: Viewing receive side but receiveTxn not yet available
  // (e.g., peg-in viewed from LBTC page before Sideswap processes it)
  if (sendTxn?.txhash != null) {
    return (transactionId: sendTxn!.txhash, explorerAsset: deliverAsset);
  }

  // Fallback 2: Viewing deliver side but sendTxn not matched
  // (e.g., external peg where we only have the receive confirmation)
  if (receiveTxn?.txhash != null) {
    return (transactionId: receiveTxn!.txhash, explorerAsset: receiveAsset);
  }

  // Fallback 3: Neither network txn found - use db hash with deliver explorer
  // (e.g., very early pending state before any network confirmation)
  return (transactionId: fallbackTxHash, explorerAsset: deliverAsset);
}
