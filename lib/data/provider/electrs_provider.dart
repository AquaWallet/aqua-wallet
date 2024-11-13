import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/data/provider/fee_estimate_provider.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:dio/dio.dart';

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
  Future<String> broadcast(String rawTx, NetworkType network,
      {bool isLowball = true}) async {
    final client = ref.read(dioProvider);
    final isBitcoin = network == NetworkType.bitcoin;

    if (isBitcoin || !isLowball) {
      try {
        // broadcast with Blockstream
        logger.d('[Electrs] Attempt broadcast with blockstream');
        final response = await client.post(
            '${getElectrsUrl(network, env, server: ElectrsServer.blockstream)}/tx',
            data: rawTx);
        return response.data as String;
      } on DioException catch (e) {
        throw _handleBroadcastError(e, ElectrsServer.blockstream);
      }
    }

    try {
      if (ref.read(featureFlagsProvider).throwAquaBroadcastErrorEnabled) {
        throw AquaTxBroadcastException();
      }

      // broadcast with Aqua node
      logger.d('[Electrs] Attempt broadcast with lowball');
      final response = await client.post(
          '${getElectrsUrl(network, env, server: ElectrsServer.aqua)}/broadcast',
          data: {'txhex': rawTx});
      return response.data as String;
    } on DioException catch (e) {
      throw _handleBroadcastError(e, ElectrsServer.aqua);
    }
  }

  Exception _handleBroadcastError(DioException e, ElectrsServer source) {
    logger.e(
        "[Electrs] $source broadcast error: ${e.response?.statusCode}, ${e.response?.data}");

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
    } else if (source == ElectrsServer.blockstream) {
      return BlockstreamTxBroadcastException();
    }

    return UnknownTxBroadcastException();
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
      logger.e(
          "[Electrs] fetch txs error: ${e.response?.statusCode}, ${e.response?.data}");
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
      logger.e(
          "[Electrs] fetch block height error: ${e.response?.statusCode}, ${e.response?.data}");
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
