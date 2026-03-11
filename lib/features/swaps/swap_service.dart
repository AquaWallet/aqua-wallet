import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:decimal/decimal.dart';

import 'swaps.dart';

abstract class SwapService {
  const SwapService({
    required this.fiatProvider,
    required this.formatter,
    required this.displayUnitsProvider,
  });

  final FiatProvider fiatProvider;
  final FormatService formatter;
  final DisplayUnitsProvider displayUnitsProvider;

  Future<bool> checkPermissions();

  Future<List<SwapAsset>> getAvailableAssets();

  Future<List<SwapPair>> getAvailablePairs({SwapAsset? from, SwapAsset? to});

  Future<SwapRate> getRate(
    SwapPair pair, {
    Decimal? amount,
    SwapOrderType? type,
  });

  Future<SwapQuote> requestQuote({
    required SwapPair pair,
    Decimal? sendAmount,
    Decimal? receiveAmount,
    SwapOrderType orderType = SwapOrderType.fixed,
  });

  Future<SwapOrder> createSendOrder(SwapOrderRequest request);

  Future<SwapOrder> createReceiveOrder(SwapOrderRequest request);

  //TODO: Need to change to two status calls:
  // 1. to stream (and also to close the stream)
  // 2. to fetch a single status
  Stream<SwapOrderStatus> getOrderStatus(String orderId);

  Future<bool> validateAddress(SwapAsset asset, String address);

  Future<void> cacheOrderToDatabase(
      String orderId, SwapOrder response, String walletId);

  Future<void> updateOrderStatus(String orderId, SwapOrderStatus status);

  Future<void> updateOrderTxId(String orderId, String txId);

  void invalidateSwapProviders(WidgetRef ref);

  Future<FeeStructure> calculateFees(SwapFeeCalculationParams params);

  Future<double> getSendNetworkFeeInFiat(SwapFeeCalculationParams param) async {
    if (param.isUsdtFeeAsset && param.usdtFeeInSats != null) {
      return param.usdtFeeInSats! / satsPerBtc;
    }

    final rate = param.btcUsdRateAtExecution;
    if (rate != null && rate > 0) {
      final feeInSats =
          param.sendNetworkFeeInSats ?? kEstimatedLiquidSendNetworkFee;
      return (feeInSats / satsPerBtc) * rate;
    }

    return 0.00;
  }

  String formatUsdtTotalFees({
    required Decimal amount,
    required FiatCurrency currency,
  }) {
    final formattedAmount = formatter.formatFiatAmount(
      amount: amount,
      specOverride: currency.format,
      withSymbol: false,
    );

    return '$formattedAmount ${Asset.usdtLiquid().ticker}';
  }
}
