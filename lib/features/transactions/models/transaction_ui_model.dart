import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_ui_model.freezed.dart';

@freezed
class TransactionUiModel with _$TransactionUiModel {
  const factory TransactionUiModel.normal({
    required DateTime createdAt,
    required String cryptoAmount,
    required Asset asset,
    required Asset? otherAsset,
    required GdkTransaction transaction,
    TransactionDbModel? dbTransaction,
    Asset? fiatAsset,
    @Default(false) bool isFailed,
    Asset? feeForAsset,
  }) = NormalTransactionUiModel;

  const factory TransactionUiModel.pending({
    String? transactionId,
    required DateTime createdAt,
    required String cryptoAmount,
    required Asset asset,
    required Asset? otherAsset,
    TransactionDbModel? dbTransaction,
    Asset? feeForAsset,
  }) = PendingTransactionUiModel;
}

extension TransactionUiModelX on TransactionUiModel {
  bool get isPending => this is PendingTransactionUiModel;

  bool get isFeeTransaction => map(
        normal: (model) => model.feeForAsset != null,
        pending: (model) => model.feeForAsset != null,
      );

  bool get isOutgoingAsset =>
      asset.id ==
      map(
        normal: (model) => model.transaction.swapOutgoingAssetId,
        pending: (model) => model.dbTransaction?.assetId,
      );

  bool get involvesUsdt {
    return (dbTransaction?.isUSDtSwap ?? false) ||
        asset.isAnyUsdt ||
        (otherAsset?.isAnyUsdt ?? false);
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

  String get blindingUrl => maybeMap(
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

  TransactionUiModel applyFeeTransactionFlag(
    GdkTransaction? networkTxn,
    Asset asset,
    List<Asset> availableAssets,
  ) {
    if (networkTxn == null) {
      return this;
    }

    final deliveredAssetId = networkTxn.getDeliverAssetId(asset);
    if (deliveredAssetId == null) {
      return this;
    }

    final deliveredAsset =
        availableAssets.firstWhereOrNull((a) => a.id == deliveredAssetId);
    if (deliveredAsset == null) {
      return this;
    }

    return map(
      normal: (model) => model.copyWith(feeForAsset: deliveredAsset),
      pending: (model) => model.copyWith(feeForAsset: deliveredAsset),
    );
  }
}

extension TransactionUiModelListX on List<TransactionUiModel> {
  TransactionUiModel findUiModelForTransaction(String transactionId) {
    return firstWhere(
      (txn) => txn.map(
        normal: (model) => model.transaction.txhash == transactionId,
        pending: (model) =>
            model.transactionId == transactionId ||
            model.dbTransaction?.txhash == transactionId,
      ),
    );
  }
}
