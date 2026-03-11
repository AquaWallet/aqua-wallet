import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/providers/providers.dart';
import 'package:aqua/logger.dart';

// Finds transactions that have been discovered by the mempool and hence are
//now available in the network transactions list, and unmarks them as ghost

final _logger = CustomLogger(FeatureFlag.transactions);

final pendingTransactionMarkingProvider = AutoDisposeAsyncNotifierProvider<
    PendingTxnMarkingNotifier,
    Map<String, List<TransactionDbModel>>>(PendingTxnMarkingNotifier.new);

class PendingTxnMarkingNotifier
    extends AutoDisposeAsyncNotifier<Map<String, List<TransactionDbModel>>> {
  @override
  FutureOr<Map<String, List<TransactionDbModel>>> build() async {
    final timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => ref.invalidateSelf(),
    );

    ref.onDispose(timer.cancel);

    final userAssets = await ref.read(assetsProvider.future);
    final localDbTxns = await ref.watch(transactionStorageProvider.future);
    final ghostTxns = localDbTxns.where((t) => t.isGhost).toList();

    final discoveredTxns = await Future.wait(userAssets.map((asset) async {
      final txns = await ref.read(networkTransactionsProvider(asset).future);
      final discoveredGhostTxnsForAsset = ghostTxns
          .where((gTxn) => txns.any((nTxn) => nTxn.txhash == gTxn.txhash))
          .toList();

      for (final txn in discoveredGhostTxnsForAsset) {
        final isPendingPeg = txn.isPeg && await _isPendingPeg(txn);
        if (!isPendingPeg) {
          await ref
              .read(transactionStorageProvider.notifier)
              .save(txn.copyWith(isGhost: false));
          _logger.info('Unmarked ghost transaction: ${txn.txhash}');
        }
      }

      return {asset.id: discoveredGhostTxnsForAsset};
    }));

    final items = discoveredTxns.fold<Map<String, List<TransactionDbModel>>>(
      {},
      (acc, curr) => acc..addAll(curr),
    );

    for (final item in items.entries) {
      final count = item.value.length;
      if (count > 0) {
        _logger.info('[${item.key}] Marked $count ghost txns');
      }
    }

    return items;
  }

  Future<bool> _isPendingPeg(TransactionDbModel transaction) async {
    final orderId = transaction.serviceOrderId;
    if (orderId == null) {
      return false;
    }

    return ref.read(pegStorageProvider.notifier).isOrderPending(orderId);
  }
}
