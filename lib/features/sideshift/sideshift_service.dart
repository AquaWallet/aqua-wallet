import 'package:coin_cz/common/decimal/decimal_ext.dart';
import 'package:coin_cz/data/models/database/swap_order_model.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideshift/sideshift.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/logger.dart';
import 'package:decimal/decimal.dart';

final _logger = CustomLogger(FeatureFlag.sideshift);

class SideshiftService implements SwapService {
  final SideshiftHttpProvider _httpProvider;
  final SwapOrderStorageNotifier _storageProvider;

  SideshiftService({
    required SideshiftHttpProvider httpProvider,
    required SwapOrderStorageNotifier storageProvider,
  })  : _httpProvider = httpProvider,
        _storageProvider = storageProvider;

  @override
  Future<bool> checkPermissions() async {
    try {
      final permissions = await _httpProvider.checkPermissions();
      return permissions.createShift;
    } catch (e) {
      throw SwapServiceAuthenticationException(
          SwapServiceSource.sideshift.displayName);
    }
  }

  @override
  Future<List<SwapAsset>> getAvailableAssets() async {
    try {
      final assets = await _httpProvider.fetchSideShiftAssetsList();
      return assets
          .map((asset) => SwapAsset(
                id: asset.id,
                name: asset.name,
                ticker: asset.coin,
              ))
          .toList();
    } catch (e) {
      throw SwapServiceCurrencyListException(
          SwapServiceSource.sideshift.displayName);
    }
  }

  @override
  Future<List<SwapPair>> getAvailablePairs(
      {SwapAsset? from, SwapAsset? to}) async {
    throw UnimplementedError(
        'getAvailablePairs is not implemented for SideShift');
  }

  @override
  Future<SwapRate> getRate(SwapPair pair,
      {Decimal? amount, SwapOrderType? type}) async {
    try {
      final fromAsset = SideshiftAssetExt.fromSwapAsset(pair.from);
      final toAsset = SideshiftAssetExt.fromSwapAsset(pair.to);

      final pairInfo =
          await _httpProvider.fetchSideShiftAssetPair(fromAsset, toAsset);

      return SwapRate(
        rate: Decimal.parse(pairInfo.rate),
        min: Decimal.parse(pairInfo.min),
        max: Decimal.parse(pairInfo.max),
      );
    } catch (e) {
      throw SwapServiceQuoteException(SwapServiceSource.sideshift.displayName);
    }
  }

  @override
  Future<SwapOrder> createReceiveOrder(SwapOrderRequest request) async {
    try {
      final fromAsset = SideshiftAssetExt.fromSwapAsset(request.from);
      final toAsset = SideshiftAssetExt.fromSwapAsset(request.to);

      final orderResponse = await _httpProvider.requestVariableOrder(
        depositCoin: fromAsset.coin,
        depositNetwork: fromAsset.network,
        settleCoin: toAsset.coin,
        settleNetwork: toAsset.network,
        receiveAddress: request.receiveAddress ?? '',
        refundAddress: request.refundAddress,
      );

      final serviceFee = SwapFee(
        type: SwapFeeType.percentageFee,
        value: DecimalExt.fromDouble(kSideshiftServiceFee, precision: 3),
        currency: SwapFeeCurrency.usd,
      );

      return SwapOrder(
        createdAt: orderResponse.createdAt ?? DateTime.now(),
        id: orderResponse.id ?? '',
        from: request.from,
        to: request.to,
        depositAddress: orderResponse.depositAddress ?? '',
        settleAddress: orderResponse.settleAddress ?? '',
        depositAmount: Decimal.parse(orderResponse.depositMin ?? '0'),
        settleAmount: Decimal.zero,
        serviceFee: serviceFee,
        depositCoinNetworkFee:
            Decimal.zero, // Not provided in variable response
        settleCoinNetworkFee:
            Decimal.parse(orderResponse.settleCoinNetworkFee ?? '0'),
        expiresAt: orderResponse.expiresAt,
        status: orderResponse.status?.toSwapOrderStatus() ??
            SwapOrderStatus.waiting,
        type: SwapOrderType.variable,
        serviceType: SwapServiceSource.sideshift,
      );
    } on NoPermissionsException {
      rethrow;
    } catch (e) {
      throw SwapServiceOrderCreationException(
          SwapServiceSource.sideshift.displayName);
    }
  }

  @override
  Future<SwapOrder> createSendOrder(SwapOrderRequest request) async {
    try {
      SwapQuote quote;

      // add buffer to prevent race condition, quote needs to be valid for 5 seconds more so order can be created.
      const bufferDuration = Duration(seconds: 5);
      if (request.quote != null &&
          request.quote!.expiresAt
              .isAfter(DateTime.now().add(bufferDuration))) {
        quote = request.quote!;
      } else {
        quote = await requestQuote(
          pair: SwapPair(from: request.from, to: request.to),
          sendAmount: request.amount,
        );
      }
      logger.debug(
          "[SideShift] createSendOrder - request: $request - quoteId: ${quote.id}");

      // Create order
      final orderResponse = await _httpProvider.requestFixedOrder(
        quoteId: quote.id,
        receiveAddress: request.receiveAddress ?? '',
        refundAddress: request.refundAddress,
      );

      final flatFee = Decimal.parse(orderResponse.depositAmount ?? '0') -
          Decimal.parse(orderResponse.settleAmount ?? '0');
      final serviceFee = SwapFee(
        type: SwapFeeType.flatFee,
        value: flatFee,
        currency: SwapFeeCurrency.usd,
      );

      //TODO: Throw on null, or make SideshiftOrder model non-null
      return SwapOrder(
        createdAt: orderResponse.createdAt ?? DateTime.now(),
        id: orderResponse.id ?? '',
        from: request.from,
        to: request.to,
        depositAddress: orderResponse.depositAddress ?? '',
        settleAddress: orderResponse.settleAddress ?? '',
        depositAmount: Decimal.parse(orderResponse.depositAmount ?? '0'),
        settleAmount: Decimal.parse(orderResponse.settleAmount ?? '0'),
        serviceFee: serviceFee,
        depositCoinNetworkFee: Decimal.zero, // Not provided in fixed response
        settleCoinNetworkFee: Decimal.zero, // Not provided in fixed response
        expiresAt: orderResponse.expiresAt,
        status: orderResponse.status?.toSwapOrderStatus() ??
            SwapOrderStatus.waiting,
        type: SwapOrderType.fixed,
        serviceType: SwapServiceSource.sideshift,
      );
    } on NoPermissionsException {
      rethrow;
    } catch (e) {
      logger.error("[SideShift] createSendOrder - error: ${e.toString()}");
      throw SwapServiceOrderCreationException(
          SwapServiceSource.sideshift.displayName);
    }
  }

  @override
  Stream<SwapOrderStatus> getOrderStatus(String orderId) async* {
    try {
      while (true) {
        final status = await _httpProvider.fetchOrderStatus(orderId);
        yield status.status?.toSwapOrderStatus() ?? SwapOrderStatus.unknown;
        await Future.delayed(const Duration(seconds: 30));
      }
    } catch (e) {
      throw SwapServiceOrderStatusException(
          SwapServiceSource.sideshift.displayName);
    }
  }

  @override
  Future<bool> validateAddress(SwapAsset asset, String address) async {
    //Sideshift doesn't provide an API to validate addresses
    return true;
  }

  @override
  Future<void> cacheOrderToDatabase(String orderId, SwapOrder order) async {
    try {
      final model = SwapOrderDbModel.fromSwapOrder(order);
      await _storageProvider.save(model);
      _logger.debug('Order cached successfully: $orderId');
    } catch (e) {
      _logger.error(
          'Error caching order to database: $e', e, StackTrace.current);
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, SwapOrderStatus status) async {
    try {
      await _storageProvider.updateOrder(orderId: orderId, status: status);
    } catch (e) {
      _logger.error('Error updating order cache: $e', e, StackTrace.current);
    }
  }

  @override
  Future<void> updateOrderTxId(String orderId, String txId) async {
    try {
      await _storageProvider.updateOrder(orderId: orderId, txHash: txId);
      _logger.debug('Order txId updated successfully: $orderId');
    } catch (e) {
      _logger.error('Error updating order txId: $e', e, StackTrace.current);
    }
  }

  @override
  void invalidateSwapProviders(WidgetRef ref) {}

  @override
  Future<SwapQuote> requestQuote({
    required SwapPair pair,
    Decimal? sendAmount,
    Decimal? receiveAmount,
    SwapOrderType orderType = SwapOrderType.fixed,
  }) async {
    try {
      final fromAsset = SideshiftAssetExt.fromSwapAsset(pair.from);
      final toAsset = SideshiftAssetExt.fromSwapAsset(pair.to);

      final quoteResponse = await _httpProvider.requestQuote(
        fromAsset: fromAsset,
        toAsset: toAsset,
        deliverAmount: sendAmount,
        settleAmount: receiveAmount,
      );

      return SwapQuote(
        id: quoteResponse.id,
        createdAt: quoteResponse.createdAt ?? DateTime.now(),
        depositCoin: quoteResponse.depositCoin ?? '',
        settleCoin: quoteResponse.settleCoin ?? '',
        depositNetwork: quoteResponse.depositNetwork ?? '',
        settleNetwork: quoteResponse.settleNetwork ?? '',
        expiresAt: quoteResponse.expiresAt ?? DateTime.now(),
        depositAmount: Decimal.parse(quoteResponse.depositAmount ?? '0'),
        settleAmount: Decimal.parse(quoteResponse.settleAmount ?? '0'),
        rate: Decimal.parse(quoteResponse.rate ?? '0'),
        affiliateId: quoteResponse.affiliateId,
      );
    } catch (e) {
      logger.error(
          '[SideShift] Error requesting quote: $e', e, StackTrace.current);
      throw SwapServiceQuoteException(SwapServiceSource.sideshift.displayName);
    }
  }
}
