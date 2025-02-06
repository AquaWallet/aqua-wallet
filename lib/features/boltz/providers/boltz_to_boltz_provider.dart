import 'package:aqua/data/provider/electrs_provider.dart';
import 'package:aqua/data/provider/isar_database_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/providers/dio_provider.dart';
import 'package:aqua/features/shared/providers/env_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:dio/dio.dart';
import 'package:aqua/logger.dart';

final _logger = CustomLogger(FeatureFlag.boltz);

/// Boltz-to-boltz txs are special in that instead of routing the ln<>lbtc swaps through boltz,
/// we use "magic routing hints" to convert to a direct lbtc send.
/// This provider is useful for watching when a receive address passed to boltz reverse swap for this
/// specific purpose has received a transaction.
final boltzToBoltzReceiveProvider = StreamProvider.autoDispose
    .family<List<String>?, String>((ref, orderId) async* {
  final storage = await ref.read(storageProvider.future);
  final swap = await storage.boltzSwapDbModels
      .where()
      .boltzIdEqualTo(orderId)
      .findFirst();

  final receiveAddress = swap?.outAddress;
  if (receiveAddress == null) yield null;

  final stream = ref.read(liquidProvider).transactionEventSubject;
  await for (var _ in stream) {
    final txs = await ref
        .read(electrsProvider)
        .fetchTransactions(receiveAddress!, NetworkType.liquid);
    yield txs;
  }
});

// ANCHOR: - Fetch Reverse Swap Bip21

/// Fetch bip21 for direct liquid send (this is a minor hack to fix an issue with Aqua > Aqua swaps)
final fetchReverseSwapBip21Provider =
    FutureProvider.family<BoltzReverseSwapBip21Response, String>(
        (ref, lnInvoice) async {
  final client = ref.read(dioProvider);
  final baseUri = ref.read(boltzEnvConfigProvider).apiUrl;

  final uri = '$baseUri/swap/reverse/$lnInvoice/bip21';

  try {
    final response = await client.get(uri);

    final json = response.data as Map<String, dynamic>;
    _logger.debug("fetchReverseSwapBip21 response: $json");

    if (json.containsKey('error')) {
      throw Exception(
          'Error calling boltz fetchReverseSwapBip21: ${json['error']}');
    } else {
      return BoltzReverseSwapBip21Response.fromJson(json);
    }
  } on DioException catch (e) {
    _logger.error(
        "fetchReverseSwapBip21 error: ${e.response?.statusCode}, ${e.response?.data}");
    throw Exception(e);
  }
});
