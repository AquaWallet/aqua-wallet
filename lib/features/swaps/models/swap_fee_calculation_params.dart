import 'package:aqua/features/settings/settings.dart';
import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'swap_fee_calculation_params.freezed.dart';

@freezed
sealed class SwapFeeCalculationParams with _$SwapFeeCalculationParams {
  const factory SwapFeeCalculationParams.sideshift({
    required Decimal depositAmount,
    required Decimal settleAmount,
    required FiatCurrency currency,
    int? sendNetworkFeeInSats,
    @Default(false) bool isUsdtFeeAsset,
    int? usdtFeeInSats,
    double? btcUsdRateAtExecution,
  }) = SideshiftFeeCalculationParams;

  const factory SwapFeeCalculationParams.changelly({
    required Decimal depositAmount,
    required Decimal settleAmount,
    required FiatCurrency currency,
    required Decimal settleCoinNetworkFee,
    int? sendNetworkFeeInSats,
    @Default(false) bool isUsdtFeeAsset,
    int? usdtFeeInSats,
    double? btcUsdRateAtExecution,
  }) = ChangellyFeeCalculationParams;
}
