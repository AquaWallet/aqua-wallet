import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:decimal/decimal.dart';

final usdtSwapFeeCalculatorServiceProvider =
    Provider.autoDispose(UsdtSwapFeeCalculatorService.new);

class UsdtSwapFeeCalculatorService {
  const UsdtSwapFeeCalculatorService(this._ref);

  final Ref _ref;

  Future<FeeStructure> calculateFeeStructure({
    required SwapServiceSource swapServiceSource,
    required Decimal depositAmount,
    required Decimal settleAmount,
    Decimal? settleCoinNetworkFee,
    int? sendNetworkFeeInSats,
    bool isUsdtFeeAsset = false,
    int? usdtFeeInSats,
    double? btcUsdRateAtExecution,
  }) async {
    const currency = FiatCurrency.usd;

    final params = switch (swapServiceSource) {
      SwapServiceSource.sideshift => SwapFeeCalculationParams.sideshift(
          depositAmount: depositAmount,
          settleAmount: settleAmount,
          currency: currency,
          sendNetworkFeeInSats: sendNetworkFeeInSats,
          isUsdtFeeAsset: isUsdtFeeAsset,
          usdtFeeInSats: usdtFeeInSats,
          btcUsdRateAtExecution: btcUsdRateAtExecution,
        ),
      SwapServiceSource.changelly => SwapFeeCalculationParams.changelly(
          depositAmount: depositAmount,
          settleAmount: settleAmount,
          currency: currency,
          settleCoinNetworkFee: settleCoinNetworkFee ?? Decimal.zero,
          sendNetworkFeeInSats: sendNetworkFeeInSats,
          isUsdtFeeAsset: isUsdtFeeAsset,
          usdtFeeInSats: usdtFeeInSats,
          btcUsdRateAtExecution: btcUsdRateAtExecution,
        ),
    };

    return _ref
        .read(swapServiceProvider(swapServiceSource))
        .calculateFees(params);
  }
}
