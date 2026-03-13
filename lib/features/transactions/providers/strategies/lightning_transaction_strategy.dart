import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lightningTransactionUiModelsProvider = Provider.autoDispose((ref) {
  return LightningTransactionUiModelCreator(
    ref: ref,
    formatter: ref.read(formatProvider),
    assetResolutionService: ref.read(assetResolutionServiceProvider),
    failureService: ref.read(txnFailureServiceProvider),
    confirmationService: ref.read(confirmationServiceProvider),
    appLocalizations: ref.read(appLocalizationsProvider),
  );
});

// Strategy for Lightning transactions (facilitated by Boltz)
//
// Handles swaps between on-chain assets (BTC/LBTC) and Lightning Network.
// Two types:
// - Submarine swap: On-chain → Lightning
// - Reverse swap: Lightning → On-chain
//
// Rules:
// - Shows on BOTH asset pages (from and to)
// - Amount is negative on sending side, positive on receiving side
class LightningTransactionUiModelCreator extends TransactionUiModelCreator {
  const LightningTransactionUiModelCreator({
    required super.ref,
    required super.formatter,
    required super.assetResolutionService,
    required super.failureService,
    required super.confirmationService,
    required super.appLocalizations,
  });

  @override
  bool shouldShowTransactionForAsset(TransactionStrategyArgs args) {
    final dbTxn = args.dbTransaction;
    if (dbTxn == null) {
      return false;
    }

    // Lightning transactions should show on the L-BTC page
    return args.asset.isLBTC && dbTxn.isBoltz;
  }

  @override
  String? getCryptoAmountForPending(TransactionStrategyArgs args) {
    final dbTxn = args.dbTransaction;
    final networkTxn = args.networkTransaction;

    if (dbTxn != null && dbTxn.ghostTxnAmount != null) {
      // For Lightning (Boltz) transactions, determine direction from the transaction type:
      // - boltzSwap (submarine): outgoing (user sends on-chain, receives Lightning)
      // - boltzReverseSwap: incoming (user sends Lightning, receives on-chain)
      final isReceiving = dbTxn.isBoltzReverseSwap || dbTxn.isBoltzRefund;
      final amount =
          isReceiving ? dbTxn.ghostTxnAmount! : -dbTxn.ghostTxnAmount!;

      return formatter.signedFormatAssetAmount(
        amount: amount,
        asset: args.asset,
        removeTrailingZeros: true,
      );
    }

    // Fallback to network transaction
    if (networkTxn != null) {
      return formatter.signedFormatAssetAmount(
        amount: networkTxn.satoshi?[args.asset.id] as int,
        asset: args.asset,
        removeTrailingZeros: true,
      );
    }

    return null;
  }

  @override
  String? getCryptoAmountForNormal(TransactionStrategyArgs args) {
    final networkTxn = args.networkTransaction;
    if (networkTxn == null) {
      // No-op: Can not proceed without network transaction
      return null;
    }

    // Lightning transactions are incoming/outgoing, not swap type
    final amount = networkTxn.satoshi?[args.asset.id] as int;
    return formatter.signedFormatAssetAmount(
      amount: amount,
      asset: args.asset,
      removeTrailingZeros: true,
    );
  }

  @override
  Asset? getOtherAsset(TransactionStrategyArgs args) {
    final resolved = _resolveAssets(args);
    return resolved.toAsset;
  }

  @override
  TransactionUiModel? createPendingListItems(TransactionStrategyArgs args) {
    if (args.dbTransaction == null && args.networkTransaction == null) {
      // No-op: Need either db transaction or network transaction
      return null;
    }

    // Failed transactions should not appear in pending list
    if (args.dbTransaction != null &&
        failureService.isFailed(args.dbTransaction!)) {
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
    final isFailed = failureService.isFailed(args.dbTransaction);

    // Failed transactions can appear without network transaction
    if (args.networkTransaction == null && !isFailed) {
      // No-op: Can not proceed without network transaction (unless failed)
      return null;
    }

    final createdAt = getCreatedAt(args);
    if (createdAt == null) {
      // No-op: Can not proceed without creation date
      return null;
    }

    // For failed transactions without network transaction, use pending amount calculation
    final cryptoAmount = args.networkTransaction != null
        ? getCryptoAmountForNormal(args)
        : getCryptoAmountForPending(args);

    if (cryptoAmount == null) {
      // No-op: Can not proceed without crypto amount
      return null;
    }

    // For failed transactions without network transaction, create a minimal GdkTransaction
    final transaction = args.networkTransaction ??
        GdkTransaction(
          txhash: args.dbTransaction?.txhash ?? '',
          createdAtTs: createdAt.microsecondsSinceEpoch,
        );

    return TransactionUiModel.normal(
      createdAt: createdAt,
      cryptoAmount: cryptoAmount,
      asset: args.asset,
      otherAsset: getOtherAsset(args),
      transaction: transaction,
      dbTransaction: args.dbTransaction,
      isFailed: isFailed,
    );
  }

  SwapAssets _resolveAssets(TransactionStrategyArgs args) {
    final dbTxn = args.dbTransaction;
    final networkTxn = args.networkTransaction;

    if (dbTxn != null) {
      // Lightning swaps are always identified via DB transaction
      // which contains the type (boltzSwap or boltzReverseSwap)
      return assetResolutionService.resolveSwapAssetsFromDb(
        dbTxn: dbTxn,
        asset: args.asset,
        availableAssets: args.availableAssets,
        networkTxn: networkTxn,
      );
    }

    return (fromAsset: null, toAsset: null);
  }

  @override
  Future<AssetTransactionDetailsUiModel?> createPendingDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final dbTxn = args.dbTransaction;
    if (dbTxn == null || !dbTxn.isBoltz) {
      return null;
    }

    // Determine transaction type (submarine swap, reverse swap, or failed)
    final isSubmarineSwap = dbTxn.type == TransactionDbModelType.boltzSwap ||
        dbTxn.type == TransactionDbModelType.boltzSendFailed;
    final isReverseSwap = dbTxn.type == TransactionDbModelType.boltzReverseSwap;
    final isRefund = dbTxn.type == TransactionDbModelType.boltzRefund;

    final feeAsset = args.availableAssets.firstWhere(
      (a) => a.id == dbTxn.feeAssetId,
      orElse: () => args.asset,
    );

    final date = dbTxn.ghostTxnCreatedAt?.formatFullDateTime ?? '';
    final isFailed = failureService.isFailed(dbTxn);

    // Submarine swap or failed send: On-chain → Lightning (shows as SEND)
    if (isSubmarineSwap) {
      final deliveredAmountSats = dbTxn.ghostTxnSideswapDeliverAmount ?? 0;

      final deliveredAmount = formatter.formatAssetAmount(
        amount: deliveredAmountSats.abs(),
        asset: args.asset,
      );

      // For pending, we only know the Boltz fee (no network fee yet)
      final boltzFeeSats = (dbTxn.ghostTxnAmount ?? 0) - deliveredAmountSats;
      final totalFeeSats = boltzFeeSats; // No network fee for pending

      final feeAmount = formatter.formatAssetAmount(
        amount: totalFeeSats,
        asset: feeAsset,
      );

      final feeAmountFiat = convertToFiat(Asset.lbtc(), totalFeeSats);

      final amountSats = deliveredAmountSats + totalFeeSats;

      final amount = amountSats > 0
          ? formatter.formatAssetAmount(
              amount: amountSats.abs(),
              asset: args.asset,
            )
          : null;

      final amountFiat =
          amountSats > 0 ? convertToFiat(Asset.lbtc(), amountSats.abs()) : null;

      final fiatValueAtTime = amountSats > 0
          ? calculateFiatAmountAtExecutionDisplay(
              dbTxn, amountSats.abs(), args.asset)
          : null;

      return AssetTransactionDetailsUiModel.send(
        transactionId: dbTxn.txhash,
        date: date,
        confirmations: appLocalizations.pending,
        isPending: true,
        isFailed: isFailed,
        deliverAmount: amount,
        deliverAmountFiat: amountFiat,
        recepientGetsAmount: deliveredAmount,
        deliverAsset: args.asset,
        feeAmount: feeAmount,
        feeAmountFiat: feeAmountFiat,
        feeAsset: feeAsset,
        receiveAddress: dbTxn.receiveAddress,
        canRbf: false,
        dbTransaction: dbTxn,
        isLightning: true,
        blindingUrl: '',
        fiatAmountAtExecutionDisplay: fiatValueAtTime,
      );
    }

    // Reverse swap: Lightning → On-chain (shows as RECEIVE)
    if (isReverseSwap) {
      // For pending reverse swaps, we only have the invoice amount
      // We don't know the received amount yet (no network transaction)
      final invoiceAmountSats = dbTxn.ghostTxnAmount ?? 0;

      final amount = formatter.formatAssetAmount(
        amount: invoiceAmountSats.abs(),
        asset: args.asset,
      );

      final amountFiat = convertToFiat(Asset.lbtc(), invoiceAmountSats.abs());

      return AssetTransactionDetailsUiModel.receive(
        transactionId: dbTxn.txhash,
        date: date,
        confirmations: appLocalizations.pending,
        isPending: true,
        receivedAmount: amount,
        receivedAmountFiat: amountFiat,
        receivedAsset: args.asset,
        dbTransaction: dbTxn,
        isLightning: true,
        blindingUrl: '',
      );
    }

    // Refund: Lightning → On-chain (shows as RECEIVE)
    if (isRefund) {
      final amountSats = dbTxn.ghostTxnAmount ?? 0;

      final amount = formatter.formatAssetAmount(
        amount: amountSats.abs(),
        asset: args.asset,
      );

      final amountFiat = convertToFiat(Asset.lbtc(), amountSats.abs());

      return AssetTransactionDetailsUiModel.receive(
        transactionId: dbTxn.txhash,
        date: date,
        confirmations: appLocalizations.pending,
        isPending: true,
        receivedAmount: amount,
        receivedAmountFiat: amountFiat,
        receivedAsset: args.asset,
        dbTransaction: dbTxn,
        isLightning: true,
        blindingUrl: '',
      );
    }

    return null;
  }

  @override
  Future<AssetTransactionDetailsUiModel?> createConfirmedDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final dbTxn = args.dbTransaction;
    if (dbTxn == null || !dbTxn.isBoltz) {
      return null;
    }

    // Determine transaction type (submarine swap, reverse swap, or failed)
    final isSubmarineSwap = dbTxn.type == TransactionDbModelType.boltzSwap ||
        dbTxn.type == TransactionDbModelType.boltzSendFailed;
    final isReverseSwap = dbTxn.type == TransactionDbModelType.boltzReverseSwap;
    final isRefund = dbTxn.type == TransactionDbModelType.boltzRefund;

    final networkTxn = args.networkTransaction;
    final boltzSwap = dbTxn.serviceOrderId != null
        ? await ref
            .read(boltzStorageProvider.notifier)
            .getSwapById(dbTxn.serviceOrderId!)
        : null;
    final feeAsset = getFeeAsset(args);
    final confirmationCount = await confirmationService.getConfirmationCount(
        args.asset, networkTxn?.blockHeight ?? 0);
    final isPending = networkTxn != null
        ? await confirmationService.isTransactionPending(
            transaction: networkTxn, asset: args.asset, dbTransaction: dbTxn)
        : false;

    final date = networkTxn != null
        ? formatDate(networkTxn.createdAtTs)
        : (dbTxn.ghostTxnCreatedAt?.formatFullDateTime ?? '');
    final confirmations = formatter.formatConfirmations(
      appLocalizations,
      confirmationCount,
    );

    // Submarine swap: On-chain → Lightning (shows as SEND)
    if (isSubmarineSwap) {
      final deliveredAmountSatsNullable = dbTxn.ghostTxnSideswapDeliverAmount;

      final deliveredAmount = formatter.formatAssetAmountOrElseNull(
        amount: deliveredAmountSatsNullable?.abs(),
        asset: args.asset,
      );
      // Calculate boltz fee: amount sent - amount received
      final int? boltzFeeSats;
      if (deliveredAmountSatsNullable != null) {
        final deliveredAmountSats = deliveredAmountSatsNullable;
        boltzFeeSats =
            (dbTxn.ghostTxnAmount ?? 0).abs() - deliveredAmountSats.abs();
      } else {
        boltzFeeSats = null;
      }
      final networkFeeSats = networkTxn?.fee ?? 0;
      final totalFeeSats =
          boltzFeeSats != null ? boltzFeeSats + networkFeeSats : null;

      final feeAmount = formatter.formatAssetAmountOrElseNull(
        amount: totalFeeSats,
        asset: feeAsset,
      );
      final feeAmountFiat =
          totalFeeSats != null ? convertToFiat(feeAsset, totalFeeSats) : null;

      final amountSats =
          deliveredAmountSatsNullable != null && totalFeeSats != null
              ? deliveredAmountSatsNullable + totalFeeSats
              : boltzSwap?.outAmount;
      final amount = formatter.formatAssetAmountOrElseNull(
        amount: amountSats?.abs(),
        asset: args.asset,
      );
      final amountFiat = amountSats != null
          ? convertToFiat(Asset.lbtc(), amountSats.abs())
          : null;

      final isFailed = failureService.isFailed(dbTxn);
      final fiatValueAtTime = amountSats != null
          ? calculateFiatAmountAtExecutionDisplay(
              dbTxn, amountSats.abs(), args.asset)
          : null;

      return AssetTransactionDetailsUiModel.send(
        transactionId: networkTxn?.txhash ?? dbTxn.txhash,
        date: date,
        confirmations: confirmations,
        isPending: isPending,
        isFailed: isFailed,
        deliverAmount: amount,
        deliverAmountFiat: amountFiat,
        recepientGetsAmount: deliveredAmount,
        deliverAsset: args.asset,
        feeAmount: feeAmount,
        feeAmountFiat: feeAmountFiat,
        feeAsset: feeAsset,
        receiveAddress: dbTxn.receiveAddress ?? boltzSwap?.invoice,
        canRbf: false,
        notes: networkTxn?.memo,
        dbTransaction: dbTxn,
        isLightning: true,
        blindingUrl: computeBlindingUrl(networkTxn, args.asset),
        fiatAmountAtExecutionDisplay: fiatValueAtTime,
      );
    }

    // Reverse swap: Lightning → On-chain (shows as RECEIVE)

    if (isReverseSwap) {
      final receivedAmountSats = networkTxn?.outputs?.firstOrNull?.satoshi ?? 0;
      final invoiceAmountSats = dbTxn.ghostTxnAmount ?? 0;
      final boltzFeeSats = invoiceAmountSats - receivedAmountSats;

      final feeAmount = formatter.formatAssetAmount(
        amount: boltzFeeSats,
        asset: feeAsset,
      );
      final amount = formatter.formatAssetAmount(
        amount: receivedAmountSats,
        asset: args.asset,
      );
      final amountFiat = convertToFiat(Asset.lbtc(), receivedAmountSats.abs());

      return AssetTransactionDetailsUiModel.receive(
        transactionId: networkTxn?.txhash ?? dbTxn.txhash,
        date: date,
        confirmations: confirmations,
        isPending: isPending,
        receivedAmount: amount,
        receivedAmountFiat: amountFiat,
        receivedAsset: args.asset,
        notes: networkTxn?.memo,
        dbTransaction: dbTxn,
        isLightning: true,
        blindingUrl: computeBlindingUrl(networkTxn, args.asset),
        feeAmount: feeAmount,
        feeAmountFiat: convertToFiat(feeAsset, boltzFeeSats),
        feeAsset: feeAsset,
      );
    }
    // Refund: Lightning → On-chain (shows as RECEIVE)
    if (isRefund) {
      final receivedAmountSats = networkTxn?.satoshi?[args.asset.id] ?? 0;
      final amount = formatter.formatAssetAmount(
        amount: receivedAmountSats,
        asset: args.asset,
      );
      final amountFiat = convertToFiat(Asset.lbtc(), receivedAmountSats.abs());
      return AssetTransactionDetailsUiModel.receive(
        transactionId: networkTxn?.txhash ?? dbTxn.txhash,
        date: date,
        confirmations: confirmations,
        isPending: isPending,
        receivedAmount: amount,
        receivedAmountFiat: amountFiat,
        receivedAsset: args.asset,
        notes: networkTxn?.memo,
        dbTransaction: dbTxn,
        isLightning: true,
        blindingUrl: computeBlindingUrl(networkTxn, args.asset),
      );
    }

    return null;
  }
}
