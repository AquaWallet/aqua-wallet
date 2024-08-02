import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';

class TransactionUiModel {
  TransactionUiModel({
    required this.createdAt,
    required this.cryptoAmount,
    required this.icon,
    required this.asset,
    required this.otherAsset,
    required this.transaction,
    this.dbTransaction,
  });

  final String createdAt;
  final String cryptoAmount;
  final String icon;
  final Asset asset;
  final Asset? otherAsset;
  final GdkTransaction transaction;
  final TransactionDbModel? dbTransaction;

  Iterable<String> inOutToBlindingString(List<GdkTransactionInOut> inOuts) {
    return inOuts
        .where((inOut) =>
            inOut.amountBlinder != null && inOut.assetBlinder != null)
        .map((inOut) {
      return '${inOut.satoshi},${inOut.assetId},${inOut.amountBlinder},${inOut.assetBlinder}';
    });
  }

  String get blindingUrl {
    if (asset.isLiquid) {
      final blindingStrings = [
        if (transaction.inputs?.isNotEmpty ?? false)
          ...inOutToBlindingString(transaction.inputs!),
        if (transaction.outputs?.isNotEmpty ?? false)
          ...inOutToBlindingString(transaction.outputs!)
      ].join(',');

      return blindingStrings.isNotEmpty
          ? '${transaction.txhash}#blinded=$blindingStrings'
          : '';
    }
    return '';
  }
}

extension TransactionUiModelX on TransactionUiModel {
  bool get isPegIn => dbTransaction?.isPeg == true && asset.isBTC;

  bool get isPegOut => dbTransaction?.isPeg == true && asset.isLBTC;

  String type(BuildContext context) {
    return switch (transaction.type) {
      _ when (dbTransaction?.isPegIn == true) =>
        context.loc.assetTransactionsTypePegIn,
      _ when (dbTransaction?.isPegOut == true) =>
        context.loc.assetTransactionsTypePegOut,
      _ when (dbTransaction?.isBoltzSwap == true) =>
        context.loc.assetTransactionsTypeBoltzSwap,
      _ when (dbTransaction?.isBoltzReverseSwap == true) =>
        context.loc.assetTransactionsTypeBoltzReverseSwap,
      GdkTransactionTypeEnum.incoming =>
        context.loc.assetTransactionsTypeReceived,
      GdkTransactionTypeEnum.outgoing => context.loc.assetTransactionsTypeSent,
      GdkTransactionTypeEnum.redeposit =>
        context.loc.assetTransactionsTypeRedeposit,
      GdkTransactionTypeEnum.swap => asset.id == transaction.swapOutgoingAssetId
          ? context.loc.assetTransactionsTypeSwapTo(otherAsset?.ticker ?? '')
          : context.loc.assetTransactionsTypeSwapFrom(otherAsset?.ticker ?? ''),
      _ => throw AssetTransactionsInvalidTypeException(),
    };
  }
}
