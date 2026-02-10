import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/features/changelly/changelly.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';
import 'package:dio/dio.dart';

class ChangellyApiService {
  final Dio _dio;

  static const baseUrl = changellyUrl;

  ChangellyApiService(this._dio);

  Future<List<String>> fetchCurrencyList() async {
    try {
      final response = await _dio.get('$baseUrl/currencies');

      final apiResponse = ChangellyCurrencyListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      return apiResponse.result;
    } on DioException catch (e) {
      logger.error('[Changelly] Currency list fetch error: ${e.message}', e,
          StackTrace.current);
      throw SwapServiceCurrencyListException('Changelly currency list');
    } catch (e) {
      logger.error('[Changelly] Unexpected error: $e');
      throw SwapServiceCurrencyListException('Unexpected error');
    }
  }

  Future<List<ChangellyPair>> fetchAvailablePairs(
    String? fromCurrency,
    String? toCurrency,
  ) async {
    try {
      Map<String, dynamic> data = {};
      if (fromCurrency != null) data['from'] = fromCurrency;
      if (toCurrency != null) data['to'] = toCurrency;

      final response = await _dio.post(
        '$baseUrl/pairs',
        data: data,
      );

      final apiResponse = ChangellyPairsResponse.fromJson(
        {'pairs': response.data},
      );
      return apiResponse.pairs;
    } on DioException catch (e) {
      logger.error('[Changelly] Available pairs fetch error: ${e.message}', e,
          StackTrace.current);
      throw SwapServicePairsFetchException();
    } catch (e) {
      logger.error('[Changelly] Unexpected error: $e');
      throw SwapServicePairsFetchException();
    }
  }

  Future<ChangellyFixedQuoteResponse> requestFixedQuote(
    ChangellyFixedRatePayload payload,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/get-fix-rate-for-amount',
        data: payload.toJson(),
      );

      final apiResponse = ChangellyFixedQuoteResponse.fromJson(response.data);
      return apiResponse;
    } catch (e) {
      throw SwapServiceQuoteException('Unexpected error');
    }
  }

  Future<ChangellyQuoteResponse> requestQuote(
    ChangellyQuotePayload payload,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/quote',
        data: payload.toJson(),
      );

      final apiResponse = ChangellyQuoteListResponse.fromJson(response.data);
      if (apiResponse.quotes.isEmpty) {
        throw SwapServiceQuoteException('No quotes available');
      }

      return apiResponse.quotes.first;
    } on DioException catch (e) {
      logger.error(
          '[Changelly] Order Quote Error: ${e.message}', e, StackTrace.current);
      throw SwapServiceQuoteException('${payload.from} to ${payload.to} swap');
    } catch (e) {
      logger.error('[Changelly] Unexpected error: $e');
      throw SwapServiceQuoteException('Unexpected error');
    }
  }

  Future<ChangellyVariableOrderResponse> requestVariableOrder(
    ChangellyVariableOrderPayload payload,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/create-transaction',
        data: payload.toJson(),
      );
      if (response.data is! Map<String, dynamic>) {
        throw SwapServiceOrderCreationException('Invalid response format');
      }
      return ChangellyVariableOrderResponse.fromJson(response.data);
    } on DioException catch (e) {
      logger.error('[Changelly] Variable Order Error: ${e.message}', e,
          StackTrace.current);
      throw SwapServiceOrderCreationException(
          '${payload.from} to ${payload.to} swap', e.toString());
    } catch (e) {
      logger.error('[Changelly] Unexpected error: $e');
      throw SwapServiceOrderCreationException('Unexpected error', e.toString());
    }
  }

  Future<ChangellyFixedOrderResponse> requestFixedOrder(
    ChangellyFixedOrderPayload payload,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/create-fix-transaction',
        data: payload.toJson(),
      );
      if (response.data is! Map<String, dynamic>) {
        throw SwapServiceOrderCreationException('Invalid response format');
      }
      return ChangellyFixedOrderResponse.fromJson(response.data);
    } on DioException catch (e) {
      logger.error(
          '[Changelly] Fixed Order Error: ${e.message}', e, StackTrace.current);
      throw SwapServiceOrderCreationException(
          '${payload.from} to ${payload.to} swap', e.toString());
    } catch (e) {
      logger.error('[Changelly] Unexpected error: $e');
      throw SwapServiceOrderCreationException('Unexpected error', e.toString());
    }
  }

  Future<ChangellyOrderStatus> fetchOrderStatus(String orderId) async {
    try {
      final response = await _dio.get('$baseUrl/status/$orderId');

      final status = response.data as String;

      return ChangellyOrderStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() == status.toLowerCase(),
        orElse: () => ChangellyOrderStatus.unknown,
      );
    } on DioException catch (e) {
      logger.error('[Changelly] Order Status Error: ${e.message}', e,
          StackTrace.current);
      throw SwapServiceOrderStatusException('Changelly order status');
    } catch (e) {
      logger.error('[Changelly] Unexpected error: $e');
      throw SwapServiceOrderStatusException('Unexpected error');
    }
  }
}

final changellyApiServiceProvider =
    AutoDisposeProvider<ChangellyApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ChangellyApiService(dio);
});
