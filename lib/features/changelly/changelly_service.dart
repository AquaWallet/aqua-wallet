import 'package:aqua/data/models/database/swap_order_model.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:decimal/decimal.dart';

import 'changelly.dart';

class ChangellyService implements SwapService {
  final ChangellyApiService _apiService;
  final SwapOrderStorageNotifier _storageProvider;

  ChangellyService({
    required ChangellyApiService apiService,
    required SwapOrderStorageNotifier storageProvider,
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
    final quote = await _apiService.requestQuote(
      from: ChangellyAsset.fromSwapAsset(pair.from).id,
      to: ChangellyAsset.fromSwapAsset(pair.to).id,
      amountFrom: amount,
    );
    return SwapRate(
      rate: Decimal.parse(quote.rate ?? '0'),
      min: Decimal.parse(quote.min ?? '0'),
      max: Decimal.parse(quote.max ?? '0'),
    );
  }

  @override
  Future<SwapOrder> createSendOrder(SwapOrderRequest request) async {
    return createOrder(request);
  }

  @override
  Future<SwapOrder> createReceiveOrder(SwapOrderRequest request) async {
    return createOrder(request);
  }

  Future<SwapOrder> createOrder(SwapOrderRequest request) async {
    final order = await _apiService.requestVariableOrder(
      from: ChangellyAsset.fromSwapAsset(request.from).id,
      to: ChangellyAsset.fromSwapAsset(request.to).id,
      amountFrom: request.amount?.toString(),
      address: request.receiveAddress!,
      refundAddress: request.refundAddress,
    );
    final swapOrder = order.toSwapOrder();
    return swapOrder;
  }

  @override
  Stream<SwapOrderStatus> getOrderStatus(String orderId) async* {
    while (true) {
      final response = await _apiService.fetchOrderStatus(orderId);
      yield ChangellyVariableOrderResponse(status: response).orderStatus;
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  @override
  Future<bool> validateAddress(SwapAsset asset, String address) {
    throw UnimplementedError();
  }

  @override
  Future<void> cacheOrderToDatabase(String orderId, SwapOrder order) async {
    await _storageProvider.save(SwapOrderDbModel.fromSwapOrder(order));
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
}
