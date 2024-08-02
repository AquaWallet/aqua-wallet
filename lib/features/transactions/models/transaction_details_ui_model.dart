import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_details_ui_model.freezed.dart';

@freezed
class AssetTransactionDetailsUiModel with _$AssetTransactionDetailsUiModel {
  const factory AssetTransactionDetailsUiModel.swap({
    required String transactionId,
    required String date,
    required int confirmationCount,
    required int requiredConfirmationCount,
    required bool isPending,
    required String deliverAmount,
    required String deliverAssetTicker,
    required String receiveAmount,
    required String receiveAssetTicker,
    String? notes,
    final TransactionDbModel? dbTransaction,
  }) = _SwapTransactionDetailsUiModel;

  const factory AssetTransactionDetailsUiModel.redeposit({
    required String transactionId,
    required String date,
    required int confirmationCount,
    required int requiredConfirmationCount,
    required bool isPending,
    required bool isConfidential,
    String? deliverAmount,
    String? deliverAssetTicker,
    required String feeAmount,
    required String feeAssetTicker,
    String? notes,
    final TransactionDbModel? dbTransaction,
  }) = _RedepositTransactionDetailsUiModel;

  const factory AssetTransactionDetailsUiModel.send({
    required String transactionId,
    required String date,
    required int confirmationCount,
    required int requiredConfirmationCount,
    required bool isPending,
    required String deliverAmount,
    required String deliverAssetTicker,
    required String feeAmount,
    required String feeAssetTicker,
    String? notes,
    final TransactionDbModel? dbTransaction,
  }) = _SendTransactionDetailsUiModel;

  const factory AssetTransactionDetailsUiModel.receive({
    required String transactionId,
    required String date,
    required int confirmationCount,
    required int requiredConfirmationCount,
    required bool isPending,
    required String receivedAmount,
    required String receivedAssetTicker,
    String? notes,
    final TransactionDbModel? dbTransaction,
  }) = _ReceiveTransactionDetailsUiModel;
}

extension AssetTransactionDetailsUiModelX on AssetTransactionDetailsUiModel {
  String type(BuildContext context) {
    if (dbTransaction?.isPegIn == true) {
      return context.loc.assetTransactionsTypePegIn;
    }
    if (dbTransaction?.isPegOut == true) {
      return context.loc.assetTransactionsTypePegOut;
    }
    if (dbTransaction?.isBoltzSwap == true) {
      return context.loc.assetTransactionsTypeBoltzSwap;
    }
    if (dbTransaction?.isBoltzReverseSwap == true) {
      return context.loc.assetTransactionsTypeBoltzReverseSwap;
    }
    return map(
      swap: (_) => context.loc.assetTransactionsTypeSwap,
      redeposit: (_) => context.loc.assetTransactionsTypeRedeposit,
      send: (_) => context.loc.assetTransactionsTypeSent,
      receive: (_) => context.loc.assetTransactionsTypeReceived,
    );
  }

  bool get isDeliverLiquid {
    final lbtc = AssetExt.lBtcMainnetTicker;
    final tLbtc = AssetExt.lBtcTestnetTicker;
    return map(
      swap: (model) =>
          model.deliverAssetTicker == lbtc || model.deliverAssetTicker == tLbtc,
      redeposit: (model) =>
          model.deliverAssetTicker == lbtc || model.deliverAssetTicker == tLbtc,
      send: (model) =>
          model.deliverAssetTicker == lbtc || model.deliverAssetTicker == tLbtc,
      receive: (model) => false,
    );
  }
}
