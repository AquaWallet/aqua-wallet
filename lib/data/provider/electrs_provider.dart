import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/data/provider/fee_estimate_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:dio/dio.dart';

final _logger = CustomLogger(FeatureFlag.electrs);

enum ElectrsServer { aqua, blockstream }

String getElectrsUrl(NetworkType network, Env env,
    {ElectrsServer server = ElectrsServer.blockstream}) {
  switch (server) {
    case ElectrsServer.blockstream:
      String baseUrl = blockstreamInfoBaseUrl;
      String envPath = env == Env.testnet ? '/testnet' : '';
      switch (network) {
        case NetworkType.bitcoin:
          return '$baseUrl$envPath/api';
        case NetworkType.liquid:
          return env == Env.testnet
              ? '$baseUrl/liquidtestnet/api'
              : '$baseUrl/liquid/api';
        case NetworkType.liquidTestnet:
          return '$baseUrl/liquidtestnet/api';
        default:
          throw Exception('Unsupported network type');
      }
    case ElectrsServer.aqua:
      switch (network) {
        case NetworkType.liquid:
          String baseUrl = aquaEsploraBaseUrl;
          if (env == Env.testnet) {
            throw Exception('Testnet not yet supported on aqua esplora');
          }
          return '$baseUrl/api/liquid';
        case NetworkType.bitcoin:
          throw Exception('Bitcoin not supported on aqua esplora');
        default:
          throw Exception('Unsupported network type');
      }
  }
}

class ElectrsClient {
  ElectrsClient(this.ref) {
    env = ref.read(envProvider);
  }

  final ProviderRef ref;
  late final Env env;

  Future<Map<TransactionPriority, double>> fetchFeeRates(
      NetworkType network) async {
    final client = ref.read(dioProvider);
    final endpoint = '${getElectrsUrl(network, env)}/fee-estimates';

    final response = await client.get(endpoint);
    final json = response.data as Map<String, dynamic>;
    return {
      TransactionPriority.high: json[TransactionPriority.high.value],
      TransactionPriority.medium: json[TransactionPriority.medium.value],
      TransactionPriority.low: json[TransactionPriority.low.value],
      TransactionPriority.min: json[TransactionPriority.min.value]
    };
  }

  /// Returns transaction ID if broadcasted successfully
  Future<String> broadcast(
    String rawTx,
    NetworkType network, {
    bool useAquaNode = false,
  }) async {
    final client = ref.read(dioProvider);
    try {
      final electrumServerUrl = useAquaNode
          ? getElectrsUrl(network, env, server: ElectrsServer.aqua)
          : getElectrsUrl(network, env, server: ElectrsServer.blockstream);
      final broadcastUrl = useAquaNode
          ? '$electrumServerUrl/broadcast'
          : '$electrumServerUrl/tx';
      final payload = useAquaNode ? {'txhex': rawTx} : rawTx;
      final response = await client.post(broadcastUrl, data: payload);
      return response.data as String;
    } on DioException catch (e) {
      throw _handleBroadcastError(e, ElectrsServer.blockstream);
    }
  }

  Exception _handleBroadcastError(DioException e, ElectrsServer source) {
    _logger.error(
        "$source broadcast error: ${e.response?.statusCode}, ${e.response?.data}");

    // Check if response data is a string (error message)
    if (e.response?.data is String) {
      return Exception(e.response!.data as String);
    }

    // Check for mempool conflict in map response
    // NOTE: This issue should be fixed with switch to DiscountCT. But this is a generic error catch and safe to leave in for a bit longer.
    // This error is happening with lowball txs when a user makes a second liquid tx within ~1 minute.
    // This is because lowball txs don't go through the mempool, and thus gdk doesn't see them until they're in a block.
    // We are catching this error and showing an alert to retry currently.
    if (e.response?.data is Map<String, dynamic>) {
      final errorData = e.response!.data as Map<String, dynamic>;
      if (errorData['error'] == 'txn-mempool-conflict') {
        return MempoolConflictTxBroadcastException();
      }
    }

    if (source == ElectrsServer.aqua) {
      return AquaTxBroadcastException();
    }

    return e;
  }

  /// Returns liquid transaction ids for an address
  Future<List<String>?> fetchTransactions(
      String address, NetworkType network) async {
    final client = ref.read(dioProvider);
    final endpoint = '${getElectrsUrl(network, env)}/address/$address/txs';

    try {
      final response = await client.get(endpoint);
      final txids =
          List<String>.from(response.data.map((tx) => tx['txid'].toString()));
      return txids;
    } on DioException catch (e) {
      _logger.error(
          "fetch txs error: ${e.response?.statusCode}, ${e.response?.data}");
      rethrow;
    }
  }

  /// Returns current block height
  Future<int> fetchBlockHeight(NetworkType network) async {
    final client = ref.read(dioProvider);
    final endpoint = '${getElectrsUrl(network, env)}/blocks/tip/height';

    try {
      final response = await client.get(endpoint);
      final blockHeight = int.parse(response.data.toString());
      return blockHeight;
    } on DioException catch (e) {
      _logger.error(
          "fetch block height error: ${e.response?.statusCode}, ${e.response?.data}");
      rethrow;
    }
  }
}

// Main Providers
final electrsProvider = Provider<ElectrsClient>(
  (ref) => ElectrsClient(ref),
);

// Convenience Providers
final fetchBlockHeightProvider =
    FutureProvider.family<int, NetworkType>((ref, network) async {
  return await ref.read(electrsProvider).fetchBlockHeight(network);
});

//ANCHOR: Exceptions
class AquaTxBroadcastException implements Exception {}

class BlockstreamTxBroadcastException implements Exception {}

class MempoolConflictTxBroadcastException implements Exception {}

class UnknownTxBroadcastException implements Exception {}
