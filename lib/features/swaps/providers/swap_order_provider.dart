import 'package:aqua/features/changelly/changelly_service.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SwapOrderNotifier
    extends AutoDisposeFamilyAsyncNotifier<SwapOrderCreationState, SwapArgs> {
  late final SwapService _service;
  late final SwapPair _pair;

  final _logger = CustomLogger(FeatureFlag.swap);

  @override
  Future<SwapOrderCreationState> build(SwapArgs arg) async {
    try {
      _pair = arg.pair;

      // if serviceProvider wasn't passed, then resolve automatically
      final serviceProvider = arg.serviceProvider ??
          ref.watch(swapServiceResolverProvider(arg.pair));

      if (serviceProvider == null) {
        throw SwapServiceGeneralException(
            'No swap service available for this pair');
      }

      // access service directly from registry
      final registry = ref.watch(swapServicesRegistryProvider);
      if (registry[serviceProvider] == null) {
        throw SwapServiceGeneralException(
            'Service not found: ${serviceProvider.displayName}');
      }
      _service = registry[serviceProvider]!;

      _logger.debug(
          'SwapOrderCreationNotifier initialized for ${_service.runtimeType}');
      return const SwapOrderCreationState();
    } catch (e, _) {
      _logger.error('Error initializing SwapOrderNotifier: $e');
      throw SwapServiceGeneralException(e.toString());
    }
  }

  Future<void> getRate({
    Decimal? amount,
    SwapOrderType type = SwapOrderType.variable,
  }) async {
    _logger
        .debug('Getting rate for pair: $_pair, amount: $amount, type: $type');
    try {
      final rate = await _service.getRate(_pair, amount: amount, type: type);
      state = AsyncValue.data(state.value!.copyWith(
        selectedPair: _pair,
        amount: amount,
        type: type,
        rate: rate,
      ));
      _logger.debug('Rate retrieved successfully: $rate');
    } catch (e, stackTrace) {
      _logger.debug('Error getting rate: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> getQuote(SwapPair pair,
      {Decimal? sendAmount,
      Decimal? receiveAmount,
      SwapOrderType type = SwapOrderType.variable}) async {
    _logger.debug(
        'Getting quote for pair: $pair, sendAmount: $sendAmount, receiveAmount: $receiveAmount, type: $type');
    try {
      final quote = await _service.requestQuote(
          pair: pair,
          sendAmount: sendAmount,
          receiveAmount: receiveAmount,
          orderType: type);
      state = AsyncValue.data(state.value!.copyWith(
        selectedPair: pair,
        amount: sendAmount,
        type: type,
        quote: quote,
      ));
      _logger.debug('Quote retrieved successfully: $quote');
    } catch (e, stackTrace) {
      _logger.debug('Error getting quote: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> createSendOrder(SwapOrderRequest request) async {
    _logger.debug('Creating send order with request: $request');
    try {
      final order = await _service.createSendOrder(request);
      await _service.cacheOrderToDatabase(order.id, order);
      state = AsyncValue.data(state.value!.copyWith(order: order));
      _logger.debug('Send order created successfully: ${order.id}');
    } catch (e, stackTrace) {
      _logger.debug('Error creating send order: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> createReceiveOrder(SwapOrderRequest request) async {
    _logger.debug('Creating receive order with request: $request');
    try {
      final order = await _service.createReceiveOrder(request);
      await _service.cacheOrderToDatabase(order.id, order);
      state = AsyncValue.data(state.value!.copyWith(order: order));
      _logger.debug('Receive order created successfully: ${order.id}');
    } catch (e, stackTrace) {
      _logger.debug('Error creating receive order: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<bool> validateAddress(SwapAsset asset, String address) async {
    try {
      return await _service.validateAddress(asset, address);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  bool get needsAmountOnReceive => _service is ChangellyService;
}

final swapOrderProvider = AutoDisposeAsyncNotifierProviderFamily<
    SwapOrderNotifier, SwapOrderCreationState, SwapArgs>(
  SwapOrderNotifier.new,
);
