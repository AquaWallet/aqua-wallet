import 'package:aqua/data/provider/electrs_provider.dart';
import 'package:aqua/data/provider/isar_database_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

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
