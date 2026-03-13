import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';

final aquaTransactionUiModelsProvider = Provider.autoDispose((ref) {
  return AquaTransactionUiModelCreator(
    ref: ref,
    formatter: ref.read(formatProvider),
    assetResolutionService: ref.read(assetResolutionServiceProvider),
    failureService: ref.read(txnFailureServiceProvider),
    confirmationService: ref.read(confirmationServiceProvider),
    appLocalizations: ref.read(appLocalizationsProvider),
    rbfService: ref.read(rbfServiceProvider),
    bitcoinProvider: ref.read(bitcoinProvider),
    liquidProvider: ref.read(liquidProvider),
  );
});

// Strategy for normal transactions (incoming, outgoing, redeposit).
//
// This strategy is used to create UI models for normal transactions that have
// sufficient confirmations and are not in pending state.
class AquaTransactionUiModelCreator extends TransactionUiModelCreator {
  const AquaTransactionUiModelCreator({
    required super.ref,
    required super.formatter,
    required super.assetResolutionService,
    required super.failureService,
    required super.confirmationService,
    required super.appLocalizations,
    required this.rbfService,
    required this.bitcoinProvider,
    required this.liquidProvider,
  });

  final RbfService rbfService;
  final BitcoinProvider bitcoinProvider;
  final LiquidProvider liquidProvider;

  @override
  bool shouldShowTransactionForAsset(TransactionStrategyArgs args) {
    // Normal transactions always ONLY show on the asset page it belongs to
    return args.dbTransaction?.assetId == args.asset.id;
  }

  @override
  String? getCryptoAmountForPending(TransactionStrategyArgs args) {
    final dbTxn = args.dbTransaction;
    final networkTxn = args.networkTransaction;
    final dbTxnAmount = dbTxn?.ghostTxnAmount;

    // For send transactions, the ghostTxnAmount is stored as positive
    // but needs to be displayed as negative
    final isSend = dbTxn?.type == TransactionDbModelType.aquaSend;

    final amount = switch (dbTxn) {
      _ when (dbTxnAmount != null) => isSend ? -dbTxnAmount : dbTxnAmount,
      _ when (networkTxn != null) => networkTxn.satoshi?[args.asset.id] as int,
      _ => null,
    };

    if (amount != null) {
      return formatter.signedFormatAssetAmount(
        amount: amount,
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
    if (networkTxn == null) {
      // No-op: Can not proceed without network transaction for confirmed txn
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
    // Normal transactions don't involve another asset
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

    final isFailed = failureService.isFailed(args.dbTransaction);

    return TransactionUiModel.normal(
      createdAt: createdAt,
      cryptoAmount: cryptoAmount,
      asset: args.asset,
      otherAsset: getOtherAsset(args),
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
      // Assume incoming transaction if dbTransaction is null
      return _createPendingIncomingDetails(args);
    }

    if (dbTxn.type != TransactionDbModelType.aquaSend) {
      //No-op: Only handle Aqua send transactions
      return null;
    }

    return _createPendingOutgoingDetails(args);
  }

  @override
  Future<AssetTransactionDetailsUiModel?> createConfirmedDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final networkTxn = args.networkTransaction;
    if (networkTxn == null) {
      //No-op: Can not proceed without network transaction
      return null;
    }

    return switch (networkTxn.type) {
      GdkTransactionTypeEnum.outgoing => await _createOutgoingDetails(args),
      GdkTransactionTypeEnum.incoming => await _createIncomingDetails(args),
      GdkTransactionTypeEnum.redeposit => await _createRedepositDetails(args),
      _ => null,
    };
  }

  Future<AssetTransactionDetailsUiModel> _createOutgoingDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final networkTxn = args.networkTransaction!;
    final amountSats = networkTxn.satoshi?[args.asset.id] as int;
    final feeAsset = getFeeAsset(args);

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
      removeTrailingZeros: false,
    );

    final feesSats =
        _calculateFeesSats(args, amountSats, feeAsset, networkTxn.fee);

    final feeAmount = formatter.formatAssetAmountOrElseNull(
      amount: feesSats,
      asset: feeAsset,
    );

    final amountFiat = convertToFiat(args.asset, -amountSats);
    final feeAmountFiat =
        feesSats != null ? convertToFiat(feeAsset, feesSats) : null;

    final isFailed = failureService.isFailed(args.dbTransaction);
    final confirmations = isPending
        ? appLocalizations.pending
        : formatter.formatConfirmations(
            appLocalizations,
            confirmationCount,
          );

    final isGhost = args.dbTransaction?.isGhost ?? false;
    final canRbf = !isGhost &&
        await rbfService.isRbfAllowed(
          asset: args.asset,
          txHash: networkTxn.txhash ?? '',
        );
    final recipientGets = feesSats != null
        ? _getRecipientAmount(args, amountSats, feesSats)
        : null;
    String? fiatValueAtTime;

    if (args.asset.isSatsAsset) {
      fiatValueAtTime = calculateFiatAmountAtExecutionDisplay(
          args.dbTransaction, -amountSats, args.asset);
    }

    return AssetTransactionDetailsUiModel.send(
      transactionId: networkTxn.txhash ?? '',
      date: formatDate(networkTxn.createdAtTs),
      confirmations: confirmations,
      isPending: isPending,
      isFailed: isFailed,
      deliverAmount: amount,
      deliverAmountFiat: amountFiat,
      deliverAsset: args.asset,
      feeAmount: feeAmount,
      feeAmountFiat: feeAmountFiat,
      feeAsset: feeAsset,
      receiveAddress: args.dbTransaction?.receiveAddress ??
          networkTxn.outputs?.firstOrNull?.address,
      blindingUrl: computeBlindingUrl(args.networkTransaction, args.asset),
      notes: networkTxn.memo,
      canRbf: canRbf,
      dbTransaction: args.dbTransaction,
      isLightning: false,
      feeForAsset: args.feeForAsset,
      recepientGetsAmount: recipientGets,
      fiatAmountAtExecutionDisplay: fiatValueAtTime,
    );
  }

  int? _calculateFeesSats(
    TransactionDetailsStrategyArgs args,
    int amountSats,
    Asset feeAsset,
    int? networkFee,
  ) {
    if (feeAsset.isUsdtLiquid) {
      final ghostTxnAmount = args.dbTransaction?.ghostTxnAmount;
      if (ghostTxnAmount == null) return null;
      return amountSats.abs() - ghostTxnAmount.abs();
    }
    return networkFee;
  }

  String _getRecipientAmount(
    TransactionDetailsStrategyArgs args,
    int amountSats,
    int networkFees,
  ) {
    final feeAsset = getFeeAsset(args);

    // If the fee asset is not the same as the asset,
    // dont subtract the fee from the amount
    if (feeAsset.id != args.asset.id) {
      return formatter.formatAssetAmount(
        amount: -amountSats,
        asset: args.asset,
        removeTrailingZeros: false,
      );
    }

    final ghostTransactionSentAmount = args.dbTransaction?.ghostTxnAmount ?? 0;
    final usdtFeeSats = -amountSats - ghostTransactionSentAmount;
    final amount = feeAsset.isAnyUsdt && args.asset.isAnyUsdt
        ? -amountSats - usdtFeeSats
        : -amountSats - networkFees;

    return formatter.formatAssetAmount(
      amount: amount,
      asset: args.asset,
      removeTrailingZeros: false,
    );
  }

  Future<AssetTransactionDetailsUiModel> _createIncomingDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final networkTxn = args.networkTransaction!;
    final amountSats = networkTxn.satoshi?[args.asset.id] as int;

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
      amount: amountSats,
      asset: args.asset,
      removeTrailingZeros: false,
    );

    final amountFiat = convertToFiat(args.asset, amountSats);

    final confirmations = isPending
        ? appLocalizations.pending
        : formatter.formatConfirmations(
            appLocalizations,
            confirmationCount,
          );

    return AssetTransactionDetailsUiModel.receive(
      transactionId: networkTxn.txhash ?? '',
      date: formatDate(networkTxn.createdAtTs),
      confirmations: confirmations,
      isPending: isPending,
      receivedAmount: amount,
      receivedAmountFiat: amountFiat,
      receivedAsset: args.asset,
      notes: networkTxn.memo,
      blindingUrl: computeBlindingUrl(args.networkTransaction, args.asset),
      dbTransaction: args.dbTransaction,
      isLightning: false,
    );
  }

  Future<AssetTransactionDetailsUiModel> _createRedepositDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final networkTxn = args.networkTransaction!;
    final isConfidential = networkTxn.outputs?.first.assetId != null;
    final amountSats = networkTxn.outputs?.first.satoshi as int;

    final confirmationCount = await confirmationService.getConfirmationCount(
      args.asset,
      args.networkTransaction?.blockHeight ?? 0,
    );
    final isPending = await confirmationService.isTransactionPending(
      transaction: args.networkTransaction!,
      asset: args.asset,
      dbTransaction: args.dbTransaction,
    );

    final amount = !isConfidential
        ? formatter.formatAssetAmount(
            amount: amountSats,
            asset: args.asset,
            removeTrailingZeros: false,
          )
        : null;

    final amountFiat = !isConfidential ? '' : null;

    final feeAmount = formatter.formatAssetAmount(
      amount: networkTxn.fee as int,
      asset: args.asset,
      removeTrailingZeros: false,
    );

    return AssetTransactionDetailsUiModel.redeposit(
      transactionId: networkTxn.txhash ?? '',
      asset: args.asset,
      date: formatDate(networkTxn.createdAtTs),
      confirmations: formatter.formatConfirmations(
        appLocalizations,
        confirmationCount,
      ),
      isPending: isPending,
      isConfidential: isConfidential,
      amount: amount ?? '',
      amountFiat: amountFiat ?? '',
      feeAmount: feeAmount,
      feeAssetTicker: args.asset.ticker,
      notes: networkTxn.memo,
      blindingUrl: computeBlindingUrl(args.networkTransaction, args.asset),
      dbTransaction: args.dbTransaction,
    );
  }

  Future<AssetTransactionDetailsUiModel> _createPendingOutgoingDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final dbTxn = args.dbTransaction!;
    final feeAsset = getFeeAsset(args);
    final date = dbTxn.ghostTxnCreatedAt?.formatFullDateTime ?? '';
    final isNegative = dbTxn.type == TransactionDbModelType.aquaSend;

    final deliveredAmount = formatter.signedFormatAssetAmount(
      amount: isNegative ? -dbTxn.ghostTxnAmount! : dbTxn.ghostTxnAmount!,
      asset: args.asset,
      removeTrailingZeros: false,
    );

    final amountSats = dbTxn.ghostTxnAmount ?? 0;
    final feeAmount = formatter.formatAssetAmount(
      amount: dbTxn.ghostTxnFee ?? 0,
      asset: feeAsset,
    );

    final amountFiat =
        convertToFiat(args.asset, isNegative ? -amountSats : amountSats);
    final feeAmountFiat = convertToFiat(feeAsset, dbTxn.ghostTxnFee ?? 0);

    final isFailed = failureService.isFailed(dbTxn);
    final canRbf = !dbTxn.isGhost &&
        await rbfService.isRbfAllowed(
          asset: args.asset,
          txHash: dbTxn.txhash,
        );

    final recipientGetsAmount = dbTxn.ghostTxnAmount != null
        ? formatter.formatAssetAmount(
            amount: amountSats,
            asset: args.asset,
            decimalPlacesOverride:
                args.asset.isAnyUsdt ? kUsdtDisplayPrecision : null,
          )
        : null;

    String? fiatValueAtTime;
    if (args.asset.isSatsAsset) {
      fiatValueAtTime = calculateFiatAmountAtExecutionDisplay(
          dbTxn, isNegative ? -amountSats : amountSats, args.asset);
    }

    return AssetTransactionDetailsUiModel.send(
      transactionId: dbTxn.txhash,
      date: date,
      confirmations: appLocalizations.pending,
      isPending: true,
      isFailed: isFailed,
      deliverAmount: deliveredAmount,
      deliverAmountFiat: amountFiat,
      deliverAsset: args.asset,
      receiveAddress: dbTxn.receiveAddress,
      feeAmount: feeAmount,
      feeAmountFiat: feeAmountFiat,
      feeAsset: feeAsset,
      canRbf: canRbf,
      dbTransaction: dbTxn,
      isLightning: false,
      feeForAsset: args.feeForAsset,
      blindingUrl: computeBlindingUrl(args.networkTransaction, args.asset),
      recepientGetsAmount: recipientGetsAmount,
      fiatAmountAtExecutionDisplay: fiatValueAtTime,
    );
  }

  Future<AssetTransactionDetailsUiModel> _createPendingIncomingDetails(
    TransactionDetailsStrategyArgs args,
  ) async {
    final dbTxn = args.dbTransaction;

    // If dbTransaction is null, it's a pending incoming transaction without DB entry
    if (dbTxn == null) {
      final networkTxn = args.networkTransaction;
      if (networkTxn == null) {
        throw Exception(
            'Cannot create pending incoming details without transaction data');
      }

      final sats = networkTxn.satoshi?[args.asset.id] as int;
      final amount = formatter.formatAssetAmount(
        amount: sats,
        asset: args.asset,
        removeTrailingZeros: false,
      );
      final amountFiat = convertToFiat(args.asset, sats);

      return AssetTransactionDetailsUiModel.receive(
        transactionId: networkTxn.txhash ?? '',
        date: formatDate(networkTxn.createdAtTs),
        confirmations: appLocalizations.pending,
        isPending: true,
        receivedAmount: amount,
        receivedAmountFiat: amountFiat,
        receivedAsset: args.asset,
        dbTransaction: null,
      );
    }

    final date = dbTxn.ghostTxnCreatedAt?.formatFullDateTime ?? '';
    final amountSats = dbTxn.ghostTxnAmount!;
    final receivedAmount = formatter.formatAssetAmount(
      amount: amountSats,
      asset: args.asset,
    );

    final amountFiat = convertToFiat(args.asset, amountSats);

    return AssetTransactionDetailsUiModel.receive(
      transactionId: dbTxn.txhash,
      date: date,
      confirmations: appLocalizations.pending,
      isPending: true,
      receivedAmount: receivedAmount,
      receivedAmountFiat: amountFiat,
      receivedAsset: args.asset,
      dbTransaction: dbTxn,
    );
  }
}
