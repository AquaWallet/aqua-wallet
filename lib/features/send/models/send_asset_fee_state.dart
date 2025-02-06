import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_asset_fee_state.freezed.dart';

@freezed
class SendAssetFeeState with _$SendAssetFeeState {
  const factory SendAssetFeeState.bitcoin({
    required int feeRate,
    required int estimatedFee,
  }) = BitcoinFee;

  const factory SendAssetFeeState.liquid({
    required int feeRate,
    required int estimatedFee,
  }) = LiquidFee;

  const factory SendAssetFeeState.liquidTaxi({
    required int lbtcFeeRate,
    required int estimatedLbtcFee,
    required double usdtFeeRate,
    required double estimatedUsdtFee,
  }) = LiquidTaxiFee;
}
