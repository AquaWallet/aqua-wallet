import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/data/provider/fee_estimate_provider.dart';
import 'package:aqua/data/provider/aqua_node_provider.dart';
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
    final shouldBroadcastWithAqua = ref.read(isAquaNodeSyncedProvider) == true;
    final isBitcoin = network == NetworkType.bitcoin;

    if (isBitcoin || !shouldBroadcastWithAqua || !isLowball) {
      // broadcast with Blockstream
      final response = await client.post(
          '${getElectrsUrl(network, env, server: ElectrsServer.blockstream)}/tx',
          data: rawTx);
      return response.data as String;
    }

    try {
      // broadcast with Aqua node
      if (ref.read(featureFlagsProvider).throwAquaBroadcastErrorEnabled) {
        throw AquaBroadcastError();
      }

      final response = await client.post(
          '${getElectrsUrl(network, env, server: ElectrsServer.aqua)}/broadcast',
          data: {'txhex': rawTx});
      return response.data as String;
    } on DioException catch (e) {
      logger.e(
          "[Electrs] Aqua broadcast error: ${e.response?.statusCode}, ${e.response?.data}. Retrying with Blockstream...");

      ref.read(isAquaNodeSyncedProvider.notifier).state = false;
      throw AquaBroadcastError();
    }
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

class AquaBroadcastError implements Exception {}
