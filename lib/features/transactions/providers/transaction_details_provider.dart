import 'dart:async';

import 'package:coin_cz/constants.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/transactions/transactions.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:intl/intl.dart';

typedef AssetTransaction = (
  BuildContext,
  NormalTransactionUiModel,
);

final assetTransactionDetailsProvider = AsyncNotifierProvider.family
    .autoDispose<
        AssetTransactionDetailsNotifier,
        AssetTransactionDetailsUiModel,
        AssetTransaction?>(AssetTransactionDetailsNotifier.new);

class AssetTransactionDetailsNotifier extends AutoDisposeFamilyAsyncNotifier<
    AssetTransactionDetailsUiModel, AssetTransaction?> {
  @override
  FutureOr<AssetTransactionDetailsUiModel> build(AssetTransaction? arg) async {
    if (arg == null) {
      throw AssetTransactionDetailsInvalidArgumentsException();
    }

    final asset = arg.$2.asset;
    final transaction = arg.$2.transaction;
    final allAssets = await ref.read(availableAssetsProvider.future);
    final allUserAssets = await ref.read(assetsProvider.future);
    final feeAsset =
        allUserAssets.firstWhere((a) => asset.isBTC ? a.isBTC : a.isLBTC);
    final network =
        asset.isBTC ? ref.read(bitcoinProvider) : ref.read(liquidProvider);

    final transactions =
        await network.getTransactions(requiresRefresh: true) ?? [];
    final updatedTransaction = transactions.firstWhereOrNull((txn) {
      return txn.txhash == transaction.txhash;
    });

    if (updatedTransaction == null) {
      throw AssetTransactionDetailsTransactionNotFoundException();
    }

    final assetList = updatedTransaction.satoshi?.keys
        .map((id) => allAssets.firstWhereOrNull((asset) => asset.id == id))
        .whereNotNull()
        .toList();
    final count = await ref
        .read(aquaProvider)
        .getConfirmationCount(
          asset: asset,
          transactionBlockHeight: updatedTransaction.blockHeight ?? 0,
        )
        .first;

    final arguments = TransactionDataArgument(
      transaction: updatedTransaction,
      transactionAsset: asset,
      feeAsset: feeAsset,
      satoshiAssets: assetList ?? [],
      confirmationCount: count,
      isPending: _isPending(asset, count),
      requiredConfirmationCount: _getRequiredConfirmationCount(asset),
      memo: updatedTransaction.memo,
      dbTransaction: arg.$2.dbTransaction,
    );

    return switch (transaction.type) {
      GdkTransactionTypeEnum.swap => _swapItemUiModels(arg.$1, arguments),
      GdkTransactionTypeEnum.redeposit => _redepositItems(arg.$1, arguments),
      GdkTransactionTypeEnum.outgoing => _outgoingItems(arg.$1, arguments),
      GdkTransactionTypeEnum.incoming => _incomingItems(arg.$1, arguments),
      _ => throw UnimplementedError(),
    };
  }

  int _getRequiredConfirmationCount(Asset asset) {
    return asset.isBTC
        ? onchainConfirmationBlockCount
        : liquidConfirmationBlockCount;
  }

  bool _isPending(Asset asset, int confirmationCount) {
    return confirmationCount < _getRequiredConfirmationCount(asset);
  }

  AssetTransactionDetailsUiModel _swapItemUiModels(
    BuildContext context,
    TransactionDataArgument arguments,
  ) {
    final transaction = arguments.transaction;
    final satoshiAssets = arguments.satoshiAssets;

    final date = formattedDate(context, transaction.createdAtTs);
    final confirmationCount = arguments.confirmationCount;

    final deliveredAsset = satoshiAssets!
        .firstWhere((asset) => asset.id == transaction.swapOutgoingAssetId);
    final deliveredAmount = ref.read(formatterProvider).formatAssetAmountDirect(
        amount: (transaction.swapOutgoingSatoshi as int).abs(),
        precision: deliveredAsset.precision,
        removeTrailingZeros: deliveredAsset.isNonSatsAsset);

    final receivedAsset = satoshiAssets
        .firstWhere((asset) => asset.id == transaction.swapIncomingAssetId);
    final receivedAmount = ref.read(formatterProvider).formatAssetAmountDirect(
        amount: transaction.swapIncomingSatoshi as int,
        precision: receivedAsset.precision,
        removeTrailingZeros: deliveredAsset.isNonSatsAsset);

    return AssetTransactionDetailsUiModel.swap(
      transactionId: transaction.txhash ?? '',
      date: date,
      confirmationCount: confirmationCount,
      requiredConfirmationCount: arguments.requiredConfirmationCount,
      isPending: arguments.isPending,
      notes: transaction.memo,
      deliverAmount: deliveredAmount,
      deliverAssetTicker: deliveredAsset.ticker,
      receiveAmount: receivedAmount,
      receiveAssetTicker: receivedAsset.ticker,
      dbTransaction: arguments.dbTransaction,
    );
  }

  AssetTransactionDetailsUiModel _redepositItems(
    BuildContext context,
    TransactionDataArgument arguments,
  ) {
    final asset = arguments.transactionAsset;
    final transaction = arguments.transaction;

    final date = formattedDate(context, transaction.createdAtTs);
    final confirmationCount = arguments.confirmationCount;

    final isConfidential = transaction.outputs?.first.assetId != null;

    final deliveredAmount = !isConfidential
        ? ref.read(formatterProvider).formatAssetAmountDirect(
            amount: transaction.outputs?.first.satoshi as int,
            precision: asset.precision,
            removeTrailingZeros: asset.isNonSatsAsset)
        : null;
    final deliveredAssetTicker = !isConfidential
        ? arguments.satoshiAssets?.firstOrNull?.ticker ?? ''
        : null;

    final feeAmount = ref.read(formatterProvider).formatAssetAmountDirect(
        amount: transaction.fee as int,
        precision: asset.precision,
        removeTrailingZeros: asset.isNonSatsAsset);
    final feeAssetTicker = asset.ticker;

    return AssetTransactionDetailsUiModel.redeposit(
      transactionId: transaction.txhash ?? '',
      date: date,
      confirmationCount: confirmationCount,
      requiredConfirmationCount: arguments.requiredConfirmationCount,
      isPending: arguments.isPending,
      isConfidential: isConfidential,
      deliverAmount: deliveredAmount,
      deliverAssetTicker: deliveredAssetTicker,
      feeAmount: feeAmount,
      feeAssetTicker: feeAssetTicker,
      notes: transaction.memo,
      dbTransaction: arguments.dbTransaction,
    );
  }

  AssetTransactionDetailsUiModel _outgoingItems(
    BuildContext context,
    TransactionDataArgument arguments,
  ) {
    final TransactionDataArgument(
      :transactionAsset,
      :transaction,
      :feeAsset,
      :confirmationCount
    ) = arguments;

    final date = formattedDate(context, transaction.createdAtTs);

    final deliveredAmount = ref.read(formatterProvider).formatAssetAmountDirect(
        amount: -(transaction.satoshi?[transactionAsset.id] as int),
        precision: transactionAsset.precision,
        removeTrailingZeros: transactionAsset.isNonSatsAsset);

    final networkFees = (arguments.dbTransaction?.type?.isPeg ?? false
            // PEG: we do estimated seconds chain fees, so we save total fee in TX db
            // if it was not saved, fallback to first TX fee
            ? arguments.dbTransaction?.estimatedFee ?? transaction.fee
            // other: take transaction fee
            : transaction.fee) ??
        // when fee not available fallback to 0
        0;

    final feeAmount = ref.read(formatterProvider).formatAssetAmountDirect(
        amount: networkFees,
        precision: feeAsset.precision,
        removeTrailingZeros: transactionAsset.isNonSatsAsset);

    return AssetTransactionDetailsUiModel.send(
      transactionId: transaction.txhash ?? '',
      date: date,
      confirmationCount: confirmationCount,
      requiredConfirmationCount: arguments.requiredConfirmationCount,
      isPending: arguments.isPending,
      deliverAmount: deliveredAmount,
      deliverAssetTicker: transactionAsset.ticker,
      feeAmount: feeAmount,
      feeAssetTicker: feeAsset.ticker,
      notes: arguments.memo,
      dbTransaction: arguments.dbTransaction,
    );
  }

  AssetTransactionDetailsUiModel _incomingItems(
    BuildContext context,
    TransactionDataArgument arguments,
  ) {
    final asset = arguments.transactionAsset;
    final transaction = arguments.transaction;

    final receivedAmount = ref.read(formatterProvider).formatAssetAmountDirect(
        amount: transaction.satoshi?[asset.id] as int,
        precision: asset.precision,
        removeTrailingZeros: asset.isNonSatsAsset);

    return AssetTransactionDetailsUiModel.receive(
      transactionId: transaction.txhash ?? '',
      date: formattedDate(context, transaction.createdAtTs),
      confirmationCount: arguments.confirmationCount,
      requiredConfirmationCount: arguments.requiredConfirmationCount,
      isPending: arguments.isPending,
      receivedAmount: receivedAmount,
      receivedAssetTicker: asset.ticker,
      notes: arguments.memo,
      dbTransaction: arguments.dbTransaction,
    );
  }

  String formattedDate(BuildContext context, int? timestamp) {
    return timestamp != null
        ? DateFormat(
                'MMM d, yyyy \'${context.loc.assetTransactionDetailsTimeAt}\' HH:mm')
            .format(DateTime.fromMicrosecondsSinceEpoch(timestamp))
        : '';
  }

  Future<void> refresh() async {
    final asset = arg?.$2.asset;
    if (asset != null) {
      ref.invalidate(networkTransactionsProvider(asset));
    }
  }
}

class AssetTransactionDetailsInvalidArgumentsException implements Exception {}

class AssetTransactionDetailsTransactionNotFoundException
    implements Exception {}

class AssetTransactionDetailsProviderUnableToLaunchLinkException
    implements Exception {}
