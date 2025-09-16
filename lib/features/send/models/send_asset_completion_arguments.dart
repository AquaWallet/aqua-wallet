import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_asset_completion_arguments.freezed.dart';

@freezed
class SendAssetCompletionArguments with _$SendAssetCompletionArguments {
  const factory SendAssetCompletionArguments({
    required int createdAt,
    required String txId,
    required Asset asset,
    required NetworkType network,
    int? amountSats,
    String? amountFiat,
    int? feeSats,
    FeeAsset? feeAsset,
    String? serviceOrderId,
    @Default(SendTransactionType.send) SendTransactionType transactionType,
  }) = _SendAssetCompletionArguments;
}
