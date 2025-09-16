import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_asset_fee_option_model.freezed.dart';

// While the Liquid fee model is a single value for now, Bitcoin has multiple
// fee rate options for the user to select, including providing their own custom
// fee rate.
//
// For that reason the [SendAssetFeeOptionModel] has an additional wrapping of
// [BitcoinFeeModel] on top of it.

@freezed
class BitcoinFeeModel with _$BitcoinFeeModel {
  factory BitcoinFeeModel.high({
    required int feeSats,
    required double feeFiat,
    required double feeRate,
  }) = BitcoinFeeModelHigh;

  factory BitcoinFeeModel.medium({
    required int feeSats,
    required double feeFiat,
    required double feeRate,
  }) = BitcoinFeeModelMedium;

  factory BitcoinFeeModel.low({
    required int feeSats,
    required double feeFiat,
    required double feeRate,
  }) = BitcoinFeeModelLow;

  factory BitcoinFeeModel.min({
    required int feeSats,
    required double feeFiat,
    required double feeRate,
  }) = BitcoinFeeModelMin;

  factory BitcoinFeeModel.custom({
    required int feeSats,
    required double feeFiat,
    required double feeRate,
  }) = BitcoinFeeModelCustom;
}

@freezed
class LiquidFeeModel with _$LiquidFeeModel {
  factory LiquidFeeModel.lbtc({
    required int feeSats,
    required double feeFiat,
    required String fiatCurrency,
    required String fiatFeeDisplay,
    required double satsPerByte,
    @Default(true) bool isEnabled,
    @Default(false) bool availableForFeePayment,
  }) = LbtcLiquidFeeModel;

  factory LiquidFeeModel.usdt({
    required int feeAmount,
    required String feeCurrency,
    required String feeDisplay,
    @Default(true) bool isEnabled,
    @Default(false) bool availableForFeePayment,
  }) = UsdtLiquidFeeModel;
}

@freezed
class SendAssetFeeOptionModel with _$SendAssetFeeOptionModel {
  factory SendAssetFeeOptionModel.bitcoin(BitcoinFeeModel fee) =
      BitcoinSendAssetFeeOptionModel;
  factory SendAssetFeeOptionModel.liquid(LiquidFeeModel fee) =
      LiquidSendAssetFeeOptionModel;
}

extension BitcoinFeeModelExt on BitcoinFeeModel {
  String label(BuildContext context) => maybeMap(
        high: (e) => context.loc.high,
        medium: (e) => context.loc.standard,
        low: (e) => context.loc.low,
        min: (e) => context.loc.minimum,
        orElse: () => '',
      );

  SendAssetFeeOptionModel toFeeOptionModel() =>
      SendAssetFeeOptionModel.bitcoin(this);
}

extension LiquidFeeModelExt on LiquidFeeModel {
  FeeAsset get feeAsset => map(
        lbtc: (e) => FeeAsset.lbtc,
        usdt: (e) => FeeAsset.tetherUsdt,
      );

  SendAssetFeeOptionModel toFeeOptionModel() =>
      SendAssetFeeOptionModel.liquid(this);
}
