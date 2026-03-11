import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ui_components/ui_components.dart';

part 'send_asset_completion_arguments.freezed.dart';

@freezed
class TransactionSuccessArguments with _$TransactionSuccessArguments {
  const factory TransactionSuccessArguments({
    required String txId,
    required NetworkType network,
    required Asset asset,
    required int createdAt,
    required AquaAssetInputUnit inputUnit,
    int? totalAmountSent,
    int? amountToReceive,
    String? amountFiat,
    int? feeSats,
    @Default(FeeAsset.lbtc) FeeAsset feeAsset,
    String? serviceOrderId,
    @Default(SendTransactionType.send) SendTransactionType transactionType,
    @Default(false) bool isReceive,
  }) = _TransactionSuccessArguments;
}
