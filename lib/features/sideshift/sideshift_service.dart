import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';

final _logger = CustomLogger(FeatureFlag.sideshift);

class SideshiftService extends SwapService {
  final SideshiftHttpProvider _httpProvider;
  final SwapOrderStorageNotifier _storageProvider;
  SideshiftService({
    required SideshiftHttpProvider httpProvider,
    required SwapOrderStorageNotifier storageProvider,
    required super.formatter,
    required super.fiatProvider,
    required super.displayUnitsProvider,
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
    } on LoadPairsException catch (e) {
      throw SwapServiceQuoteException(
          SwapServiceSource.sideshift.displayName, e.message);
    } catch (e) {
      throw SwapServiceQuoteException(
          SwapServiceSource.sideshift.displayName, e.toString());
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

      final depositMin = orderResponse.depositMin;

      // If sender pays fees, we need to adjust the deposit amount accordingly
      final depositAmount = request.senderPaysFees
          ? depositMin + (depositMin * serviceFee.value)
          : depositMin;

      return SwapOrder(
        createdAt: orderResponse.createdAt,
        id: orderResponse.id,
        from: request.from,
        to: request.to,
        depositAddress: orderResponse.depositAddress,
        settleAddress: orderResponse.settleAddress,
        depositAmount: depositAmount,
        settleAmount: Decimal.zero,
        serviceFee: serviceFee,
        depositCoinNetworkFee:
            Decimal.zero, // Not provided in variable response
        settleCoinNetworkFee: orderResponse.settleCoinNetworkFee,
        expiresAt: orderResponse.expiresAt,
        status: orderResponse.status.toSwapOrderStatus(),
        type: SwapOrderType.variable,
        serviceType: SwapServiceSource.sideshift,
      );
    } on NoPermissionsException {
      rethrow;
    } catch (e) {
      throw SwapServiceOrderCreationException(
          SwapServiceSource.sideshift.displayName, e.toString());
    }
  }

  Future<SwapQuote> _getQuote(SwapOrderRequest request) async {
    // add buffer to prevent race condition, quote needs to be valid for 5 seconds more so order can be created.
    const bufferDuration = Duration(seconds: 5);
    if (request.quote != null &&
        request.quote!.expiresAt.isAfter(DateTime.now().add(bufferDuration))) {
      return request.quote!;
    }
    // Sender or Receiver pays fees?
    if (request.senderPaysFees) {
      return await requestQuote(
        pair: SwapPair(from: request.from, to: request.to),
        receiveAmount: request.amount,
      );
    }

    return await requestQuote(
      pair: SwapPair(from: request.from, to: request.to),
      sendAmount: request.amount,
    );
  }

  @override
  Future<SwapOrder> createSendOrder(SwapOrderRequest request) async {
    try {
      final quote = await _getQuote(request);

      // Create order
      final orderResponse = await _httpProvider.requestFixedOrder(
        quoteId: quote.id,
        receiveAddress: request.receiveAddress ?? '',
        refundAddress: request.refundAddress,
      );

      final serviceFee = SwapFee(
        type: SwapFeeType.flatFee,
        value: orderResponse.depositAmount - orderResponse.settleAmount,
        currency: SwapFeeCurrency.usd,
      );

      //TODO: Throw on null, or make SideshiftOrder model non-null
      return SwapOrder(
        createdAt: orderResponse.createdAt,
        id: orderResponse.id,
        from: request.from,
        to: request.to,
        depositAddress: orderResponse.depositAddress,
        settleAddress: orderResponse.settleAddress,
        depositAmount: orderResponse.depositAmount,
        settleAmount: orderResponse.settleAmount,
        serviceFee: serviceFee,
        depositCoinNetworkFee: Decimal.zero, // Not provided in fixed response
        settleCoinNetworkFee: Decimal.zero, // Not provided in fixed response
        expiresAt: orderResponse.expiresAt,
        status: orderResponse.status.toSwapOrderStatus(),
        type: SwapOrderType.fixed,
        serviceType: SwapServiceSource.sideshift,
      );
    } on NoPermissionsException {
      rethrow;
    } catch (e) {
      logger.error("[SideShift] createSendOrder - error: ${e.toString()}");
      throw SwapServiceOrderCreationException(
        SwapServiceSource.sideshift.displayName,
        e is OrderException ? e.message : e.toString(),
      );
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
  Future<void> cacheOrderToDatabase(
      String orderId, SwapOrder response, String walletId) async {
    try {
      final model =
          SwapOrderDbModel.fromSwapOrder(response, walletId: walletId);
      await _storageProvider.save(model);
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
      throw SwapServiceQuoteException(
          SwapServiceSource.sideshift.displayName, e.toString());
    }
  }

  @override
  Future<FeeStructure> calculateFees(SwapFeeCalculationParams params) async {
    final p = params as SideshiftFeeCalculationParams;

    // Sideshift: Fixed 0.9% service fee, network fee is the remainder
    final serviceFee = p.depositAmount *
        DecimalExt.fromDouble(kSideshiftServiceFee, precision: 3);
    final totalFees = p.depositAmount - p.settleAmount;
    final receiveNetworkFees = totalFees - serviceFee;

    final estimatedSendNetworkFeeUsd = await getSendNetworkFeeInFiat(p);

    final sendNetworkFeeDecimal =
        DecimalExt.fromDouble(estimatedSendNetworkFeeUsd);

    final calculatedTotalFees =
        serviceFee + receiveNetworkFees + sendNetworkFeeDecimal;
    final totalFeesCrypto = formatUsdtTotalFees(
      amount: calculatedTotalFees,
      currency: p.currency,
    );

    return FeeStructure.usdtSwap(
      serviceFee: serviceFee.toDouble(),
      serviceFeePercentage: kSideshiftServiceFee * 100,
      receiveNetworkFee: receiveNetworkFees.toDouble(),
      estimatedSendNetworkFee: estimatedSendNetworkFeeUsd,
      totalFees: calculatedTotalFees.toDouble(),
      totalFeesCrypto: totalFeesCrypto,
    );
  }
}
