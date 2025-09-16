import 'package:coin_cz/features/boltz/models/boltz_broadcast_tx_response.dart';
import 'package:coin_cz/features/shared/providers/dio_provider.dart';
import 'package:coin_cz/features/shared/providers/env_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:coin_cz/logger.dart';

final _logger = CustomLogger(FeatureFlag.boltz);

final boltzBroadcastProvider =
    FutureProvider.family<BoltzBroadcastTransactionResponse, String>(
        (ref, transactionHex) async {
  final client = ref.read(dioProvider);
  final baseUri = ref.read(boltzEnvConfigProvider).apiUrl;
  final uri = '$baseUri/broadcasttransaction';

  try {
    final response = await client.post(
      uri,
      data: {
        'currency': 'L-BTC',
        'transactionHex': transactionHex,
      },
    );

    final json = response.data as Map<String, dynamic>;
    _logger.debug("broadcast transaction response: $json");

    if (json.containsKey('error')) {
      final errorResponse =
          BoltzBroadcastTransactionErrorResponse.fromJson(json);
      throw Exception('Error broadcasting transaction: ${errorResponse.error}. '
          'Timeout ETA: ${errorResponse.timeoutEta}. '
          'Timeout Block Height: ${errorResponse.timeoutBlockHeight}');
    } else {
      return BoltzBroadcastTransactionResponse.fromJson(json);
    }
  } on DioException catch (e) {
    _logger.error(
        "broadcast transaction error: ${e.response?.statusCode}, ${e.response?.data}");
    throw Exception(e);
  }
});
