import 'package:aqua/logger.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:dio/dio.dart';

enum TransactionPriority { high, medium, low }

final priorityBlockLookup = {
  TransactionPriority.high: '1',
  TransactionPriority.medium: '10',
  TransactionPriority.low: '144'
};

getApiUrl(NetworkType network) =>
    'https://blockstream.info${network == NetworkType.liquid ? '/liquid' : ''}/api';

class ElectrsClient {
  ElectrsClient(this.ref);

  final ProviderRef ref;

  Future<Map<TransactionPriority, double>> fetchFeeRates(
      NetworkType network) async {
    final client = ref.read(dioProvider);
    final endpoint = '${getApiUrl(network)}/fee-estimates';

    final response = await client.get(endpoint);
    final json = response.data as Map<String, dynamic>;
    return {
      TransactionPriority.high:
          json[priorityBlockLookup[TransactionPriority.high]],
      TransactionPriority.medium:
          json[priorityBlockLookup[TransactionPriority.medium]],
      TransactionPriority.low:
          json[priorityBlockLookup[TransactionPriority.low]]
    };
  }

  /// Returns transaction ID if broadcasted succesfully
  Future<String> broadcast(String rawTx, NetworkType network) async {
    final client = ref.read(dioProvider);
    final endpoint = '${getApiUrl(network)}/tx';

    logger.d('electrs broadcast endpoint: $endpoint');

    try {
      final response = await client.post(endpoint, data: rawTx);
      return response.data as String;
    } on DioException catch (e) {
      logger.e(
          "[Electrs client] broadcast error: ${e.response?.statusCode}, ${e.response?.data}");
      rethrow;
    }
  }

  /// Returns liquid transaction ids for an address
  Future<List<String>?> fetchTransactions(
      String address, NetworkType network) async {
    final client = ref.read(dioProvider);
    final endpoint = '${getApiUrl(network)}/address/$address/txs';

    try {
      final response = await client.get(endpoint);
      final txids =
          List<String>.from(response.data.map((tx) => tx['txid'].toString()));
      logger.d("[Boltz] existing txids: $txids - for address: $address");
      return txids;
    } on DioException catch (e) {
      logger.e(
          "[Electrs client] fetch txs error: ${e.response?.statusCode}, ${e.response?.data}");
      rethrow;
    }
  }

  /// Returns current block height
  Future<int> fetchBlockHeight(NetworkType network) async {
    final client = ref.read(dioProvider);
    final endpoint = '${getApiUrl(network)}/blocks/tip/height';

    try {
      final response = await client.get(endpoint);
      final blockHeight = int.parse(response.data.toString());
      return blockHeight;
    } on DioException catch (e) {
      logger.e(
          "[Electrs client] fetch block height error: ${e.response?.statusCode}, ${e.response?.data}");
      rethrow;
    }
  }
}

final electrsProvider = Provider<ElectrsClient>(
  (ref) => ElectrsClient(ref),
);

final fetchBlockHeightProvider =
    FutureProvider.family<int, NetworkType>((ref, network) async {
  return await ref.read(electrsProvider).fetchBlockHeight(network);
});
