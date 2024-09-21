import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:intl/intl.dart';

typedef GhostTransaction = (
  BuildContext,
  GhostTransactionUiModel,
);

final ghostTransactionDetailsProvider = AsyncNotifierProvider.family
    .autoDispose<
        GhostTransactionDetailsNotifier,
        AssetTransactionDetailsUiModel,
        GhostTransaction?>(GhostTransactionDetailsNotifier.new);

class GhostTransactionDetailsNotifier extends AutoDisposeFamilyAsyncNotifier<
    AssetTransactionDetailsUiModel, GhostTransaction?> {
  @override
  FutureOr<AssetTransactionDetailsUiModel> build(GhostTransaction? arg) async {
    if (arg == null) {
      throw AssetTransactionDetailsInvalidArgumentsException();
    }

    final asset = arg.$2.asset;
    final allAssets = ref.read(assetsProvider).asData?.value ?? [];
    final feeAsset =
        allAssets.firstWhere((a) => asset.isBTC ? a.isBTC : a.isLBTC);

    return switch (arg.$2.dbTransaction!.type) {
      TransactionDbModelType.boltzReverseSwap => _incomingItems(arg, feeAsset),
      _ => _outgoingItems(arg, feeAsset),
    };
  }

  AssetTransactionDetailsUiModel _outgoingItems(
    GhostTransaction arguments,
    Asset feeAsset,
  ) {
    final context = arguments.$1;
    final uiModel = arguments.$2;
    final asset = uiModel.asset;
    final transaction = uiModel.dbTransaction!;
    final createdAt = transaction.ghostTxnCreatedAt;
    final date = formattedDate(context, createdAt);
    final deliveredAmount = ref.read(formatterProvider).signedFormatAssetAmount(
          amount: transaction.ghostTxnAmount!,
          precision: asset.precision,
        );
    final feeAmount = ref.read(formatterProvider).formatAssetAmountDirect(
          amount: transaction.ghostTxnFee ?? 0,
          precision: feeAsset.precision,
        );

    return AssetTransactionDetailsUiModel.send(
      transactionId: transaction.txhash,
      date: date,
      confirmationCount: 0,
      requiredConfirmationCount: 99,
      isPending: true,
      deliverAmount: deliveredAmount,
      deliverAssetTicker: asset.ticker,
      feeAmount: feeAmount,
      feeAssetTicker: feeAsset.ticker,
      dbTransaction: transaction,
    );
  }

  AssetTransactionDetailsUiModel _incomingItems(
    GhostTransaction arguments,
    Asset feeAsset,
  ) {
    final context = arguments.$1;
    final uiModel = arguments.$2;
    final asset = uiModel.asset;
    final transaction = uiModel.dbTransaction!;
    final createdAt = transaction.ghostTxnCreatedAt;
    final date = formattedDate(context, createdAt);
    final receivedAmount = ref.read(formatterProvider).formatAssetAmountDirect(
          amount: transaction.ghostTxnAmount!,
          precision: asset.precision,
        );

    return AssetTransactionDetailsUiModel.receive(
      transactionId: transaction.txhash,
      date: date,
      confirmationCount: 0,
      requiredConfirmationCount: 999,
      isPending: true,
      receivedAmount: receivedAmount,
      receivedAssetTicker: asset.ticker,
      dbTransaction: transaction,
    );
  }

  String formattedDate(BuildContext context, DateTime? date) {
    return date != null
        ? DateFormat(
                'MMM d, yyyy \'${context.loc.assetTransactionDetailsTimeAt}\' HH:mm')
            .format(date)
        : '';
  }

  Future<void> refresh() async {
    final asset = arg?.$2.asset;
    if (asset != null) {
      ref.invalidate(rawTransactionsProvider(asset));
    }
  }
}
