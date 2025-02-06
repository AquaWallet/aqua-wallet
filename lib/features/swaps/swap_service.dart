import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';

import 'swaps.dart';

abstract class SwapService {
  Future<bool> checkPermissions();
  Future<List<SwapAsset>> getAvailableAssets();
  Future<List<SwapPair>> getAvailablePairs({SwapAsset? from, SwapAsset? to});
  Future<SwapRate> getRate(SwapPair pair,
      {Decimal? amount, SwapOrderType? type});
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
  Future<void> cacheOrderToDatabase(String orderId, SwapOrder response);
  Future<void> updateOrderStatus(String orderId, SwapOrderStatus status);
  Future<void> updateOrderTxId(String orderId, String txId);
  void invalidateSwapProviders(WidgetRef ref);
}
