import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_details_ui_model.freezed.dart';

@freezed
class AssetTransactionDetailsUiModel with _$AssetTransactionDetailsUiModel {
  const factory AssetTransactionDetailsUiModel.peg({
    required String orderId,
    required String transactionId,
    required String date,
    required int confirmationCount,
    required bool isPending,
    required String deliverAmount,
    required Asset deliverAsset,
    required String receiveAmount,
    required Asset receiveAsset,
    required String feeAmount,
    required String feeAmountFiat,
    required Asset feeAsset,
    required String depositAddress,
    required String swapServiceName,
    required String swapServiceUrl,
    String? blindingUrl,
    String? notes,
    final TransactionDbModel? dbTransaction,
    Asset? explorerAsset,
  }) = PegTransactionDetailsUiModel;

  const factory AssetTransactionDetailsUiModel.swap({
    required String orderId,
    required String transactionId,
    required String date,
    required int confirmationCount,
    required bool isPending,
    required String deliverAmount,
    required Asset deliverAsset,
    required String receiveAmount,
    required Asset receiveAsset,
    required String feeAmount,
    required String feeAmountFiat,
    required Asset feeAsset,
    required String depositAddress,
    required String swapServiceName,
    required String swapServiceUrl,
    String? blindingUrl,
    String? notes,
    final TransactionDbModel? dbTransaction,
  }) = SwapTransactionDetailsUiModel;

  const factory AssetTransactionDetailsUiModel.redeposit({
    required String transactionId,
    required Asset asset,
    required String date,
    required String confirmations,
    required bool isPending,
    required bool isConfidential,
    required String amount,
    required String amountFiat,
    required String feeAmount,
    required String feeAssetTicker,
    String? blindingUrl,
    String? notes,
    final TransactionDbModel? dbTransaction,
  }) = RedepositTransactionDetailsUiModel;

  const factory AssetTransactionDetailsUiModel.send({
    required String transactionId,
    required String date,
    required String confirmations,
    required bool isPending,
    required bool isFailed,
    String? deliverAmount,
    String? deliverAmountFiat,
    required Asset deliverAsset,
    String? feeAmount,
    String? feeAmountFiat,
    required Asset feeAsset,
    String? recepientGetsAmount,
    String? receiveAddress,
    String? blindingUrl,
    required bool canRbf,
    String? notes,
    final TransactionDbModel? dbTransaction,
    @Default(false) bool isLightning,

    /// When non-null, this transaction is a network fee paid for sending
    /// this asset (e.g., L-BTC fee for a USDT or DEPIX send).
    Asset? feeForAsset,
    String? fiatAmountAtExecutionDisplay,
  }) = SendTransactionDetailsUiModel;

  const factory AssetTransactionDetailsUiModel.receive({
    required String transactionId,
    required String date,
    required String confirmations,
    required bool isPending,
    required String receivedAmount,
    required String receivedAmountFiat,
    required Asset receivedAsset,
    String? blindingUrl,
    String? notes,
    final TransactionDbModel? dbTransaction,
    @Default(false) bool isLightning,
    String? feeAmount,
    String? feeAmountFiat,
    Asset? feeAsset,
  }) = ReceiveTransactionDetailsUiModel;
}

extension PegTransactionDetailsUiModelExt on PegTransactionDetailsUiModel {
  bool get isDirectPegInWithNoFee =>
      isPending && deliverAsset.isBTC && dbTransaction?.ghostTxnFee == null;
}

extension SendTransactionDetailsUiModelExt on SendTransactionDetailsUiModel {
  bool get isFeeTransaction => feeForAsset != null;
}
