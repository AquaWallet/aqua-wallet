import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';

final assetTransactionDetailsProvider = AsyncNotifierProvider.family
    .autoDispose<
        AssetTransactionDetailsNotifier,
        AssetTransactionDetailsUiModel,
        TransactionDetailsArgs>(AssetTransactionDetailsNotifier.new);

// Responsible for creating transaction details UI models for a given asset.
class AssetTransactionDetailsNotifier extends AutoDisposeFamilyAsyncNotifier<
    AssetTransactionDetailsUiModel, TransactionDetailsArgs> {
  @override
  FutureOr<AssetTransactionDetailsUiModel> build(
      TransactionDetailsArgs arg) async {
    final networkTxns =
        await ref.read(networkTransactionsProvider(arg.asset).future);
    final localDbTxns = ref.read(transactionStorageProvider).valueOrNull ?? [];
    final availableAssets = ref.read(availableAssetsProvider).value ?? [];

    final networkTxn =
        networkTxns.firstWhereOrNull((t) => t.txhash == arg.transactionId);
    TransactionDbModel? dbTxn = localDbTxns.firstWhereOrNull((t) {
      if (t.txhash == arg.transactionId) return true;
      if (t.serviceOrderId == arg.transactionId) return true;
      return false;
    });

    // If not found in transactionStorage, check pegStorage for peg orders
    if (arg.asset.isSwappable) {
      final pegOrders = await ref.read(pegStorageProvider.future);
      final pegOrder = pegOrders.findMatchingOrder(
        transactionId: arg.transactionId,
        asset: arg.asset,
        outputs: networkTxn?.outputs,
      );
      if (pegOrder != null) {
        // Prefer peg order over non-peg db entries
        final pegDbModel = TransactionDbModel.fromPegOrderDbModel(
          pegOrder,
          walletId: pegOrder.walletId ?? '',
        );
        if (dbTxn == null || !dbTxn.isPeg) {
          dbTxn = pegDbModel;
        }
      }
    }

    ref.listen(pegStatusProvider, (prev, curr) {
      final prevState = prev?.consolidatedStatus?.state;
      final currState = curr.consolidatedStatus?.state;
      if (dbTxn?.isPeg == true && prevState != currState) {
        Future.microtask(() => ref.invalidateSelf());
      }
    });

    if (networkTxn == null && dbTxn == null) {
      throw AssetTransactionDetailsInvalidArgumentsException();
    }

    final strategy = ref.read(transactionUiModelsFactoryProvider).create(
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
          asset: arg.asset,
        );

    final args = TransactionDetailsStrategyArgs(
      asset: arg.asset,
      availableAssets: availableAssets,
      dbTransaction: dbTxn,
      networkTransaction: networkTxn,
    );

    final details = networkTxn != null
        ? await strategy.createConfirmedDetails(args)
        : await strategy.createPendingDetails(args);

    if (details == null) {
      throw AssetTransactionDetailsInvalidArgumentsException();
    }

    return details;
  }

  Future<void> refresh() async {
    ref.invalidate(networkTransactionsProvider(arg.asset));
  }
}
