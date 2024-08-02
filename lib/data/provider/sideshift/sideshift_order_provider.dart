import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/models/send_asset_arguments.dart';
import 'package:aqua/features/send/providers/send_asset_provider.dart';
import 'package:aqua/features/send/providers/send_asset_transaction_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/providers/providers.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

// Providers //////////////////////////////////////////////////////////////////

// Transaction state

final _transactionStateProvider =
    StreamProvider.autoDispose<SideshiftTransactionState>((ref) async* {
  yield* ref.watch(sideshiftOrderProvider)._transactionStateSubject;
});

final transactionStateProvider =
    Provider.autoDispose<SideshiftTransactionState>((ref) {
  return ref.watch(_transactionStateProvider).asData?.value ??
      const SideshiftTransactionState.complete();
});

// Order In Progress

final inProgressOrderProvider =
    Provider.autoDispose<SideshiftOrderStatusResponse?>((ref) {
  final order = ref.watch(_currentOrderStatusStreamProvider).asData?.value;
  logger.d('[SideShift] inProgressOrderProvider: $order');
  if (order?.status == OrderStatus.waiting) {
    return order;
  }
  return null;
});

// Pending Order

final _pendingOrderStreamProvider =
    StreamProvider.autoDispose<SideshiftOrder?>((ref) async* {
  yield* ref.watch(sideshiftOrderProvider)._pendingOrderSubject;
});

final sideshiftPendingOrderProvider =
    Provider.autoDispose<SideshiftOrder?>((ref) {
  return ref.watch(_pendingOrderStreamProvider).asData?.value;
});

final sideShiftPendingOrderCacheProvider =
    StateProvider.autoDispose<SideshiftOrder?>((ref) {
  return null;
});

// Order Result

final orderResultProvider = Provider.autoDispose<SideshiftOrder?>((ref) {
  return ref.watch(_pendingOrderStreamProvider).asData?.value;
});

// Order status

final _currentOrderStatusStreamProvider =
    StreamProvider.autoDispose<SideshiftOrderStatusResponse>((ref) async* {
  yield* ref.watch(sideshiftOrderProvider)._currentOrderStatusStream;
});

final currentOrderStatusProvider =
    Provider.autoDispose<SideshiftOrderStatusResponse?>((ref) {
  return ref.watch(_currentOrderStatusStreamProvider).asData?.value;
});

final orderStatusProvider = StreamProvider.family
    .autoDispose<AsyncValue<SideshiftOrderStatusResponse>, String>(
        (ref, shiftId) {
  return ref
      .watch(sideshiftOrderProvider)
      .orderStatusStream(shiftId)
      .map<AsyncValue<SideshiftOrderStatusResponse>>(
          (response) => AsyncValue.data(response))
      .onErrorReturnWith(
          (error, stackTrace) => AsyncValue.error(error, stackTrace))
      .startWith(const AsyncValue.loading());
});

// Cache gdk tx for onchain deposit
final sideswapGDKTransactionProvider =
    StateProvider.autoDispose<GdkNewTransactionReply?>((ref) => null);

// Order State Provider

final sideshiftOrderProvider = Provider<SideshiftOrderProvider>((ref) {
  return SideshiftOrderProvider(ref);
});

class SideshiftOrderProvider {
  SideshiftOrderProvider(this._ref) {
    _ref.onDispose(() {
      logger.d('[SideShift] onDispose');
      _transactionStateSubject.close();
      _pendingOrderSubject.close();
      _shiftOrderStreamStopAllSubject.close();
      _shiftCurrentOrderStreamStopSubject.close();
    });
  }

  final ProviderRef _ref;

  // Transaction state

  final _transactionStateSubject = BehaviorSubject<SideshiftTransactionState>();

  void setTransactionState(SideshiftTransactionState state) {
    _transactionStateSubject.add(state);
    logger.d('[SideShift] setTransactionState: $state');
  }

  // Pending order

  final _pendingOrderSubject = PublishSubject<SideshiftOrder?>();

  void setPendingOrder(SideshiftOrder? order) {
    _pendingOrderSubject.add(order);
    _ref.read(sideShiftPendingOrderCacheProvider.notifier).state = order;
    logger.d('[SideShift] SetPendingOrder ${order?.id}');
  }

  // Current Order status

  late final Stream<SideshiftOrderStatusResponse> _currentOrderStatusStream =
      Rx.combineLatest2(
    Stream<int>.periodic(const Duration(seconds: 5), (e) => e).startWith(0),
    _pendingOrderSubject.stream,
    (_, order) => order?.id,
  ).takeUntil(_shiftCurrentOrderStreamStopSubject.stream).doOnData((id) {
    logger
        .d('[SideShift] Checking status for order $id in current order stream');
  }).switchMap((orderId) {
    return orderId == null
        ? const Stream<SideshiftOrderStatusResponse>.empty()
        : Stream.value(null).asyncMap((_) async {
            final res = await _ref
                .read(sideshiftHttpProvider)
                .fetchOrderStatus(orderId);

            // cache updated order
            await _saveResponseToDatabase(orderId: orderId, response: res);

            logger
                .d('[SideShift] Caching order $orderId status: ${res.status}');
            return Future.value(res);
          });
  }).doOnError((error, stackTrace) {
    logger.e('[SideShift] $error');
    logger.e('[SideShift] stackTrace');
  }).asBroadcastStream();

  // Current Order Stream Stop

  final _shiftCurrentOrderStreamStopSubject = PublishSubject<void>();

  void setShiftCurrentOrderStreamStop() {
    _shiftCurrentOrderStreamStopSubject.add(null);
  }

  // Order from shiftId status

  Stream<SideshiftOrderStatusResponse> orderStatusStream(String shiftId) {
    return Stream<int>.periodic(const Duration(seconds: 5), (e) => e)
        .startWith(0)
        .takeUntil(_shiftOrderStreamStopAllSubject.stream)
        .doOnData((value) {
      logger
          .d('[SideShift] Checking status for order $shiftId in status stream');
    }).asyncMap((_) async {
      try {
        final res =
            await _ref.read(sideshiftHttpProvider).fetchOrderStatus(shiftId);
        logger.d(
            '[SideShift] Order $shiftId status: ${res.status} in status stream');

        // cache updated order
        await _saveResponseToDatabase(orderId: shiftId, response: res);

        return res;
      } catch (error, _) {
        logger.e('[SideShift] $error');
        throw OrdersStatusException(error.toString());
      }
    }).asBroadcastStream();
  }

  // Stop all order streams

  final _shiftOrderStreamStopAllSubject = PublishSubject<void>();

  void setShiftOrderStreamStopAll() {
    logger.d('[SideShift] -- stop watching all order streams --');
    _shiftOrderStreamStopAllSubject.add(null);
  }

  void stopAllStreams() {
    _pendingOrderSubject.add(null);
    _shiftCurrentOrderStreamStopSubject.add(null);
    _shiftOrderStreamStopAllSubject.add(null);
  }

  // Order placement //////////////
  Future<void> placeReceiveOrder({
    required SideshiftAsset deliverAsset,
    required SideshiftAsset receiveAsset,
  }) async {
    try {
      logger.d(
          '[SideShift] Create receive order - deliverAsset: $deliverAsset - receiveAsset: $receiveAsset');

      // get receive address
      final isBTC = receiveAsset.network == bitcoinNetwork;
      final address = isBTC
          ? await _ref.read(bitcoinProvider).getReceiveAddress()
          : await _ref.read(liquidProvider).getReceiveAddress();
      var receiveAddressValue = address?.address;
      if (receiveAddressValue == null) {
        logger.d('[SideShift] Receive address is null');
        final error = ReceivingAddressException();
        return Future.error(error);
      }

      setTransactionState(const SideshiftTransactionState.loading());
      await placeVariableRateOrder(
        deliverAsset: deliverAsset,
        receiveAsset: receiveAsset,
        receiveAddress: receiveAddressValue,
      );
    } catch (e) {
      if (e is GdkNetworkException) {
        setOrderError(GdkTransactionException(e));
        throw Exception(e.errorMessage());
      } else if (e is OrderException) {
        setOrderError(e);
        throw Exception("${e.message}");
      }
      logger.d('[SideShift] Place Receive Order Error:');
      logger.e('[SideShift]', e);
      setTransactionState(const SideshiftTransactionState.complete());
      rethrow;
    }
  }

  Future<void> placeSendOrder({
    required SideshiftAsset deliverAsset,
    required SideshiftAsset receiveAsset,
    String? refundAddress,
    String? receiveAddress,
    Decimal? amount,
    SideShiftAssetPairInfo? exchangeRate,
  }) async {
    try {
      logger.d(
          '[SideShift] Create send order - deliverAsset: $deliverAsset - receiveAsset: $receiveAsset');
      logger.d(
          '[SideShift] Create send order - amount: $amount - refundAddress: $refundAddress - receiveAddress: $receiveAddress)');

      var refundAddressValue = refundAddress;
      var receiveAddressValue = receiveAddress;

      // handle input errors
      if (receiveAddressValue == null) {
        logger.d('[SideShift] Receive address is null');
        final error = ReceivingAddressException();
        return Future.error(error);
      }

      if (refundAddressValue == null) {
        logger.d('[SideShift] Refund address is null');
        final error = RefundAddressException();
        return Future.error(error);
      }

      if (exchangeRate == null) {
        logger.d('[SideShift] Pair info (with exchange rate) is null');
        final error = MissingPairInfoException();
        return Future.error(error);
      }

      if (amount == null) {
        logger.d('[SideShift] Deliver amount is null');
        final error = DeliverAmountRequiredException();
        return Future.error(error);
      }

      final lbtcBalance = await _ref.read(balanceProvider).getLBTCBalance();
      final usdtBalance =
          await _ref.read(balanceProvider).getUsdtLiquidBalance();
      if (lbtcBalance <= 0 && usdtBalance <= 0) {
        logger.d('[SideShift] Not enough LBTC to pay network fee');
        final error = FeeBalanceException();
        return Future.error(error);
      }

      final balance =
          await _ref.read(walletBalanceProvider).getWalletBalance(deliverAsset);
      if (balance == null || amount > balance) {
        logger.d('[SideShift] Deliver amount exceed wallet balance');
        final error = DeliverAmountExceedBalanceException();
        return Future.error(error);
      }

      final min = Decimal.tryParse(exchangeRate.min) ?? Decimal.zero;
      if (amount < min) {
        logger.d('[SideShift] Deliver Amount Error: $amount <= $min');
        final error = MinDeliverAmountException(min, deliverAsset.id);
        return Future.error(error);
      }

      final max = Decimal.tryParse(exchangeRate.max) ?? Decimal.zero;
      if (amount > max) {
        logger.d('[SideShift] Deliver Amount Error: $amount <= $min');
        final error = MaxDeliverAmountException(max, deliverAsset.id);
        return Future.error(error);
      }

      final quote = await _ref.read(sideshiftHttpProvider).requestQuote(
            fromAsset: deliverAsset,
            toAsset: receiveAsset,
            settleAmount: amount,
          );

      setTransactionState(const SideshiftTransactionState.loading());
      await placeFixedRateOrder(
        deliverAsset: deliverAsset,
        receiveAsset: receiveAsset,
        refundAddress: refundAddressValue,
        receiveAddress: receiveAddressValue,
        amount: amount,
        quote: quote,
      );
    } catch (e) {
      if (e is GdkNetworkException) {
        setOrderError(GdkTransactionException(e));
        throw Exception(e.errorMessage());
      } else if (e is OrderException) {
        setOrderError(e);
        throw Exception("${e.message}");
      }
      logger.d('[SideShift] Place Send Order Error:');
      logger.e('[SideShift]', e, StackTrace.current);
      setTransactionState(const SideshiftTransactionState.complete());
      rethrow;
    }
  }

  // Variable Rate Order

  Future<void> placeVariableRateOrder({
    required SideshiftAsset deliverAsset,
    required SideshiftAsset receiveAsset,
    required String receiveAddress,
    String? refundAddress,
  }) async {
    setTransactionState(const SideshiftTransactionState.loading());
    final response =
        await _ref.read(sideshiftHttpProvider).requestVariableOrder(
              refundAddress: refundAddress,
              receiveAddress: receiveAddress,
              depositCoin: deliverAsset.coin.toLowerCase(),
              depositNetwork: deliverAsset.network.toLowerCase(),
              settleCoin: receiveAsset.coin.toLowerCase(),
              settleNetwork: receiveAsset.network.toLowerCase(),
            );
    setPendingOrder(response);

    // cache order with empty status
    if (response.id != null) {
      final orderId = response.id!;
      final res = SideshiftOrderStatusResponse(id: orderId);
      await _saveResponseToDatabase(orderId: orderId, response: res);
    }
  }

  // Fixed Rate Order

  Future<void> placeFixedRateOrder({
    required SideshiftAsset deliverAsset,
    required SideshiftAsset receiveAsset,
    required String refundAddress,
    required String receiveAddress,
    required Decimal amount,
    required SideshiftQuoteResponse quote,
  }) async {
    setTransactionState(const SideshiftTransactionState.loading());

    final response = await _ref.read(sideshiftHttpProvider).requestFixedOrder(
          quoteId: quote.id,
          refundAddress: refundAddress,
          receiveAddress: receiveAddress,
        );

    logger.d('[SideShift] Internal Order Quote ID: ${quote.id}');
    logger.d('[SideShift] Internal Order Order Response: $response');
    setPendingOrder(response);

    // cache order with empty status
    if (response.id != null) {
      final orderId = response.id!;
      final res = SideshiftOrderStatusResponse(id: orderId);
      await _saveResponseToDatabase(orderId: orderId, response: res);
    }
  }

  // create tx

  Future<void> createOnchainTxForSwap(FeeAsset feeAsset, bool sendAll,
      {bool isLowball = true}) async {
    switch (feeAsset) {
      case FeeAsset.lbtc:
        await createGdkTxForSwap(sendAll, isLowball: isLowball);
      case FeeAsset.tetherUsdt:
        await createTaxiTxForSwap(sendAll, isLowball: isLowball);
      case FeeAsset.btc:
        assert(false, 'BTC fee asset not supported for sideshift');
    }
  }

  Future<void> createTaxiTxForSwap(bool sendAll,
      {bool isLowball = true}) async {
    final pendingOrder = _ref.read(sideShiftPendingOrderCacheProvider);
    if (pendingOrder == null) {
      throw Exception('[Send][Sideshift] No pending order found');
    }
    logger.d('[Send][Sideshift] PendingOrder found: ${pendingOrder.id}}');

    final fixedPendingOrder = pendingOrder as SideshiftFixedOrderResponse;
    final depositAddress = fixedPendingOrder.depositAddress;
    final depositAmountStr = fixedPendingOrder.depositAmount;
    if (depositAddress == null) {
      throw Exception('Deposit address is null');
    }
    if (depositAmountStr == null) {
      throw Exception('Deposit amount is null');
    }
    Decimal depositAmount = Decimal.zero;
    try {
      depositAmount = Decimal.parse(depositAmountStr);
    } catch (e) {
      logger.e('[SideShift] could not parse deposit amount');
    }

    // usdt in liquid is represented as "sats", ie, $1 is represented as 100,000,000
    final depositAmountPrecision =
        (depositAmount * Decimal.fromInt(satsPerBtc)).toInt();
    await _ref
        .read(sendAssetTransactionProvider.notifier)
        .executeTaxiTransaction(
            depositAddress, depositAmountPrecision, sendAll, isLowball);
  }

  Future<GdkNewTransactionReply> createGdkTxForSwap(bool sendAll,
      {bool isLowball = true}) async {
    // get order
    final pendingOrder = _ref.read(sideShiftPendingOrderCacheProvider);
    if (pendingOrder == null) {
      throw Exception('[Send][Sideshift] No pending order found');
    }
    logger.d('[Send][Sideshift] PendingOrder found: ${pendingOrder.id}}');

    // setup
    final receiveAsset = _ref.read(sendAssetProvider);
    final fixedPendingOrder = pendingOrder as SideshiftFixedOrderResponse;
    final isFixedOrder = fixedPendingOrder.type == OrderType.fixed;
    final depositAddress = fixedPendingOrder.depositAddress;
    final receiveAddress = fixedPendingOrder.settleAddress;
    final depositAmountStr = fixedPendingOrder.depositAmount;
    if (depositAddress == null || receiveAddress == null) {
      throw Exception('Deposit or receive address is null');
    }
    if (depositAmountStr == null) {
      throw Exception('Deposit amount is null');
    }
    Decimal depositAmount = Decimal.zero;
    try {
      depositAmount = Decimal.parse(depositAmountStr);
    } catch (e) {
      logger.e('[SideShift] could not parse deposit amount');
    }

    // get pair
    final SideshiftAssetPair assetPair = SideshiftAssetPair(
      from: SideshiftAsset.usdtLiquid(),
      to: receiveAsset == Asset.usdtEth()
          ? SideshiftAsset.usdtEth()
          : SideshiftAsset.usdtTron(),
    );
    logger.d(
        '[SideShift] create fixed rate gdk tx - currentPairInfo: ${assetPair.from.toString()}');

    // calculate amount in sats to send and if sendAll
    const precision =
        8; // TODO: hardcoded for now, but should be dynamic on Asset when that's returned in endpoint
    final assetBalance =
        await _ref.read(walletBalanceProvider).getWalletBalance(assetPair.from);
    final assetBalanceSatoshi = await _ref
        .read(formatterProvider)
        .parseAssetAmount(
            amount: assetBalance.toString(), precision: precision);
    // note: this is the amount configured with the asset's precision value.
    // eg, for usdt, to send $1.01 you enter 101000000 in the gdk tx
    final amountSatoshi = await _ref
        .read(formatterProvider)
        .parseAssetAmount(amount: depositAmountStr, precision: precision);

    logger.d(
        '[SideShift] gdk amount to send: $depositAmount - with precision: $amountSatoshi');
    logger.d(
        '[SideShift] gdk amount to send - assetBalance with precision: $assetBalanceSatoshi');

    assert(depositAddress.isNotEmpty == true);
    assert(receiveAddress.isNotEmpty == true);

    final deliverAsset = _ref.read(manageAssetsProvider).liquidUsdtAsset;
    logger.d(
        '[SideShift] gdk amount to send - deliverAssetId: ${deliverAsset.id}');
    final initialTransactionReply = await _ref
        .read(sendAssetTransactionProvider.notifier)
        .createGdkTransaction(
            amountWithPrecision: amountSatoshi,
            address: depositAddress,
            asset: deliverAsset,
            isLowball: isLowball);

    // If the order is set to send max amount from wallet then recreate the
    // sideshift fixed rate order with fee deducted from it. Pass it to gdk
    // as well.
    //
    // Note: This use case is specific to BTC and L-BTC assets, all other
    // assets should be sent as is wether it is partial or maximum amount.
    final (GdkNewTransactionReply, SideshiftFixedOrderResponse) gdkArgs;
    if (isFixedOrder && sendAll) {
      final refundAddress = fixedPendingOrder.refundAddress;
      final gdkRate = initialTransactionReply.feeRate;
      final gdkFee = initialTransactionReply.fee;
      if (gdkFee == null) {
        throw Exception('Transaction fee not found in initial request');
      }
      if (gdkRate == null) {
        throw Exception('Transaction fee rate not found in initial request');
      }

      final fee = DecimalExt.fromDouble(gdkFee / 100000000);
      logger.d('[SideShift] Fiat Fee: $fee');

      if (fee <= Decimal.zero) {
        throw Exception('Transaction fee cannot be less than zero');
      }

      final revisedQuote = await _ref.read(sideshiftHttpProvider).requestQuote(
            fromAsset: assetPair.from,
            toAsset: assetPair.to,
            deliverAmount: depositAmount - fee,
          );
      logger.d('[SideShift] Revised Quote ID: ${revisedQuote.id}');
      logger.d('[SideShift] Revised Order Quote: $revisedQuote');

      final revisedOrderResponse =
          await _ref.read(sideshiftHttpProvider).requestFixedOrder(
                quoteId: revisedQuote.id,
                refundAddress: refundAddress,
                receiveAddress: receiveAddress,
                checkPermission: false,
              );
      setPendingOrder(revisedOrderResponse);

      logger.d('[SideShift] Revised Order Response: $revisedOrderResponse');

      final revisedTxnResult = await _ref
          .read(sendAssetTransactionProvider.notifier)
          .createGdkTransaction(
              address: revisedOrderResponse.depositAddress!,
              amountWithPrecision: assetBalanceSatoshi,
              asset: _ref.read(manageAssetsProvider).liquidUsdtAsset,
              isLowball: isLowball);

      gdkArgs = (revisedTxnResult, revisedOrderResponse);
    } else {
      gdkArgs = (initialTransactionReply, fixedPendingOrder);
    }

    // cache tx
    _ref.read(sideswapGDKTransactionProvider.notifier).state = gdkArgs.$1;

    logger.d('[SideShift] createGdkTransaction response: ${gdkArgs.$1}');

    return gdkArgs.$1;
  }

  Future<void> _saveResponseToDatabase({
    required String orderId,
    required SideshiftOrderStatusResponse response,
  }) async {
    final model = SideshiftOrderDbModel.fromSideshiftOrderResponse(response);
    await _ref
        .read(sideshiftStorageProvider.notifier)
        .save(model.copyWith(orderId: orderId));
  }
}
