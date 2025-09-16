import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/transactions/transactions.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_ui_model.freezed.dart';

@freezed
class TransactionUiModel with _$TransactionUiModel {
  const factory TransactionUiModel.normal({
    required String createdAt,
    required String cryptoAmount,
    required String icon,
    required Asset asset,
    required Asset? otherAsset,
    required GdkTransaction transaction,
    TransactionDbModel? dbTransaction,
    @Default(false) bool isRbfSuccess,
  }) = NormalTransactionUiModel;

  const factory TransactionUiModel.ghost({
    required String createdAt,
    required String cryptoAmount,
    required String icon,
    required Asset asset,
    TransactionDbModel? dbTransaction,
  }) = GhostTransactionUiModel;
}

extension TransactionUiModelX on TransactionUiModel {
  bool get isPegIn => dbTransaction?.isPeg == true && asset.isBTC;

  bool get isPegOut => dbTransaction?.isPeg == true && asset.isLBTC;

  bool get isGhost => this is GhostTransactionUiModel;

  String type(BuildContext context) {
    return map(
      normal: (model) => switch (model.transaction.type) {
        _ when (dbTransaction?.isPegIn == true) =>
          context.loc.assetTransactionsTypePegIn,
        _ when (dbTransaction?.isPegOut == true) =>
          context.loc.assetTransactionsTypePegOut,
        _ when (dbTransaction?.isBoltzSwap == true) =>
          context.loc.assetTransactionsTypeBoltzSwap,
        _ when (dbTransaction?.isBoltzReverseSwap == true) =>
          context.loc.assetTransactionsTypeBoltzReverseSwap,
        _ when (dbTransaction?.isAquaSend == true) =>
          context.loc.assetTransactionsTypeSent,
        _ when (dbTransaction?.isUSDtSwap == true) => context.loc.usdtSwap,
        _ when (dbTransaction?.isTopUp == true) => context.loc
            .assetTransactionsTypeTopup(dbTransaction!.serviceAddress!),
        _ when (dbTransaction?.isBoltzRefund == true) =>
          context.loc.assetTransactionsTypeBoltzRefund,
        _ when (dbTransaction?.isBoltzSendFailed == true) =>
          context.loc.assetTransactionsTypeBoltzSendFailed,
        GdkTransactionTypeEnum.incoming => context.loc.received,
        GdkTransactionTypeEnum.outgoing =>
          context.loc.assetTransactionsTypeSent,
        GdkTransactionTypeEnum.redeposit =>
          context.loc.assetTransactionsTypeRedeposit,
        GdkTransactionTypeEnum.swap => asset.id ==
                model.transaction.swapOutgoingAssetId
            ? context.loc
                .assetTransactionsTypeSwapTo(model.otherAsset?.ticker ?? '')
            : context.loc
                .assetTransactionsTypeSwapFrom(model.otherAsset?.ticker ?? ''),
        _ => throw AssetTransactionsInvalidTypeException(),
      },
      ghost: (model) => switch (model.dbTransaction) {
        _ when (dbTransaction?.isPegIn == true) =>
          context.loc.assetTransactionsTypePegIn,
        _ when (dbTransaction?.isPegOut == true) =>
          context.loc.assetTransactionsTypePegOut,
        _ when (dbTransaction?.isBoltzSwap == true) =>
          context.loc.assetTransactionsTypeBoltzSwap,
        _ when (dbTransaction?.isBoltzReverseSwap == true) =>
          context.loc.assetTransactionsTypeBoltzReverseSwap,
        _ when (dbTransaction?.isAquaSend == true) =>
          context.loc.assetTransactionsTypeSent,
        _ when (dbTransaction?.isBoltzRefund == true) =>
          context.loc.assetTransactionsTypeBoltzRefund,
        _ when (dbTransaction?.isBoltzSendFailed == true) =>
          context.loc.assetTransactionsTypeBoltzSendFailed,
        _ => '',
      },
    );
  }

  Iterable<String> inOutToBlindingString(List<GdkTransactionInOut> inOuts) {
    return inOuts
        .where((inOut) =>
            inOut.amountBlinder != null && inOut.assetBlinder != null)
        .map((inOut) => '${inOut.satoshi},'
            '${inOut.assetId},'
            '${inOut.amountBlinder},'
            '${inOut.assetBlinder}');
  }

  String get blindingUrl {
    return maybeMap(
      normal: (model) {
        if (asset.isLiquid) {
          final blindingStrings = [
            if (model.transaction.inputs?.isNotEmpty ?? false)
              ...inOutToBlindingString(model.transaction.inputs!),
            if (model.transaction.outputs?.isNotEmpty ?? false)
              ...inOutToBlindingString(model.transaction.outputs!)
          ].join(',');

          return blindingStrings.isNotEmpty
              ? '${model.transaction.txhash}#blinded=$blindingStrings'
              : '';
        }
        return '';
      },
      orElse: () => '',
    );
  }
}
