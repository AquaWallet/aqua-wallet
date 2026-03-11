import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:decimal/decimal.dart';

import 'changelly.dart';

class ChangellyService extends SwapService {
  final ChangellyApiService _apiService;
  final SwapOrderStorageNotifier _storageProvider;

  ChangellyService({
    required ChangellyApiService apiService,
    required SwapOrderStorageNotifier storageProvider,
    required super.formatter,
    required super.fiatProvider,
    required super.displayUnitsProvider,
  })  : _apiService = apiService,
        _storageProvider = storageProvider;

  @override
  Future<bool> checkPermissions() async {
    return true; // Changelly doesn't have a specific permissions check
  }

  @override
  Future<List<SwapAsset>> getAvailableAssets() async {
    final currencies = await _apiService.fetchCurrencyList();
    return currencies.map((c) => ChangellyAsset(id: c).toSwapAsset()).toList();
  }

  @override
  Future<List<SwapPair>> getAvailablePairs(
      {SwapAsset? from, SwapAsset? to}) async {
    final fromId = from != null ? ChangellyAsset.fromSwapAsset(from).id : null;
    final toId = to != null ? ChangellyAsset.fromSwapAsset(to).id : null;

    final pairs = await _apiService.fetchAvailablePairs(fromId, toId);
    return pairs
        .map((p) => SwapPair(
              from: ChangellyAsset(id: p.from).toSwapAsset(),
              to: ChangellyAsset(id: p.to).toSwapAsset(),
            ))
        .toList();
  }

  @override
  Future<SwapRate> getRate(SwapPair pair,
      {Decimal? amount, SwapOrderType? type}) async {
    final payload = ChangellyFixedRatePayload(
        from: ChangellyAsset.fromSwapAsset(pair.from).id,
        to: ChangellyAsset.fromSwapAsset(pair.to).id,
        amountFrom: '100');
    final quote = await _apiService.requestFixedQuote(payload);
    return SwapRate(
      rate: Decimal.parse(quote.result),
      min: Decimal.parse(quote.min),
      max: Decimal.parse(quote.max),
    );
  }

  @override
  Future<SwapOrder> createSendOrder(SwapOrderRequest request) async {
    return createFixedOrder(request);
  }

  @override
  Future<SwapOrder> createReceiveOrder(SwapOrderRequest request) async {
    return createVariableOrder(request);
  }

  Future<SwapOrder> createFixedOrder(SwapOrderRequest request) async {
    if (request.receiveAddress == null || request.refundAddress == null) {
      throw SwapServiceOrderCreationException(
          'Receive address and refund address are required');
    }
    final payload = ChangellyFixedRatePayload(
      from: ChangellyAsset.fromSwapAsset(request.from).id,
      to: ChangellyAsset.fromSwapAsset(request.to).id,
      amountFrom: request.amount.toString(),
    );
    final quote = await _apiService.requestFixedQuote(payload);

    final orderPayload = ChangellyFixedOrderPayload(
      rateId: quote.id,
      from: ChangellyAsset.fromSwapAsset(request.from).id,
      to: ChangellyAsset.fromSwapAsset(request.to).id,
      amountFrom: request.senderPaysFees ? null : request.amount?.toString(),
      amountTo: request.senderPaysFees ? request.amount?.toString() : null,
      address: request.receiveAddress!,
      refundAddress: request.refundAddress!,
    );
    final order = await _apiService.requestFixedOrder(orderPayload);
    final swapOrder = order.toSwapOrder();
    return swapOrder;
  }

  Future<SwapOrder> createVariableOrder(SwapOrderRequest request) async {
    final payload = ChangellyVariableOrderPayload(
      from: ChangellyAsset.fromSwapAsset(request.from).id,
      to: ChangellyAsset.fromSwapAsset(request.to).id,
      address: request.receiveAddress!,
      amountFrom: request.amount?.toString(),
    );
    final order = await _apiService.requestVariableOrder(payload);
    final swapOrder = order.toSwapOrder();
    return swapOrder;
  }

  @override
  Stream<SwapOrderStatus> getOrderStatus(String orderId) async* {
    while (true) {
      final response = await _apiService.fetchOrderStatus(orderId);
      yield changellyToSwapOrderStatus(response);
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  @override
  Future<bool> validateAddress(SwapAsset asset, String address) {
    throw UnimplementedError();
  }

  @override
  Future<void> cacheOrderToDatabase(
      String orderId, SwapOrder response, String walletId) async {
    await _storageProvider
        .save(SwapOrderDbModel.fromSwapOrder(response, walletId: walletId));
  }

  @override
  Future<void> updateOrderStatus(String orderId, SwapOrderStatus status) async {
    await _storageProvider.updateOrder(orderId: orderId, status: status);
  }

  @override
  Future<void> updateOrderTxId(String orderId, String txId) async {
    await _storageProvider.updateOrder(orderId: orderId, txHash: txId);
  }

  @override
  void invalidateSwapProviders(WidgetRef ref) {
    // TODO: Implement invalidateSwapProviders
    throw UnimplementedError();
  }

  @override
  Future<SwapQuote> requestQuote(
      {required SwapPair pair,
      Decimal? sendAmount,
      Decimal? receiveAmount,
      SwapOrderType orderType = SwapOrderType.fixed}) {
    // TODO: implement requestQuote
    throw UnimplementedError();
  }

  @override
  Future<FeeStructure> calculateFees(SwapFeeCalculationParams params) async {
    final p = params as ChangellyFeeCalculationParams;

    // Changelly fee breakdown from API (per Changelly docs):
    // - amountExpectedFrom (depositAmount): What user sends
    // - amountExpectedTo (settleAmount): Quoted amount BEFORE network fee deduction
    // - networkFee (settleCoinNetworkFee): Network fee deducted from amountExpectedTo
    // - User actually receives: settleAmount - settleCoinNetworkFee
    //
    // Formula:
    // serviceFee = depositAmount - settleAmount
    // totalFees = depositAmount - (settleAmount - networkFee)
    // totalFees = serviceFee + networkFee + sendNetworkFee
    final serviceFee = p.depositAmount - p.settleAmount;
    final serviceFeePercentage = p.depositAmount > Decimal.zero
        ? ((serviceFee / p.depositAmount).toDouble() * 100)
        : 0.0;

    final estimatedSendNetworkFeeUsd = await getSendNetworkFeeInFiat(p);

    final sendNetworkFeeDecimal =
        DecimalExt.fromDouble(estimatedSendNetworkFeeUsd);

    final calculatedTotalFees =
        serviceFee + p.settleCoinNetworkFee + sendNetworkFeeDecimal;
    final totalFeesCrypto = formatUsdtTotalFees(
      amount: calculatedTotalFees,
      currency: p.currency,
    );

    return FeeStructure.usdtSwap(
      serviceFee: serviceFee.toDouble(),
      serviceFeePercentage: serviceFeePercentage,
      receiveNetworkFee: p.settleCoinNetworkFee.toDouble(),
      estimatedSendNetworkFee: estimatedSendNetworkFeeUsd,
      totalFees: calculatedTotalFees.toDouble(),
      totalFeesCrypto: totalFeesCrypto,
    );
  }
}
