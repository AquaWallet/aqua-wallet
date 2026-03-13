import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/wallet/providers/providers.dart';
import 'package:aqua/logger.dart';
import 'package:boltz/boltz.dart';
import 'package:isar/isar.dart';

final _logger = CustomLogger(FeatureFlag.transactionStorage);

const kTransactionBoxName = 'transactions';

/// Temporary cache for sideswap receive address.
/// Needed because swap/peg operations are disjointed - the swap request is sent
/// to sideswap and the rest of the flow is handled asynchronously upon websocket
/// response, which does not include the receive address.
final sideswapReceiveAddressCacheProvider =
    StateNotifierProvider<SideswapAddressCacheNotifier, String>(
        (_) => SideswapAddressCacheNotifier());

class SideswapAddressCacheNotifier extends StateNotifier<String> {
  SideswapAddressCacheNotifier() : super('');

  void clear() => state = '';

  void set(String address) => state = address;
}

//ANCHOR - Public-facing Transaction Storage Notifier

final transactionStorageProvider =
    AsyncNotifierProvider<TransactionStorageNotifier, List<TransactionDbModel>>(
        TransactionStorageNotifier.new);

abstract class TransactionStorage {
  Future<void> save(TransactionDbModel model);
  Future<void> clear();
  Future<void> clearByWalletId(String walletId);
  Future<void> clearGhostTransactions();
  Future<void> updateTxHash({
    required String serviceOrderId,
    required String newTxHash,
  });
  Future<void> updateReceiveAddressForBoltzId({
    required String boltzId,
    required String newReceiveAddress,
  });
  Future<void> markBoltzGhostTxn(String serviceOrderId,
      {int? amount, int? fee});
  Future<void> saveBoltzRefundTxn({
    required LbtcLnSwap boltzSwap,
    required String txId,
  });
  Future<void> updateReverseSwapClaim({
    required String boltzId,
    required String claimTxId,
    required String receiveAddress,
    required int outAmount,
    required int fee,
  });

  Future<void> updateTransactionNote({
    required String txHash,
    required String note,
  });

  Future<void> clearFromMemory();
}

class TransactionStorageNotifier extends AsyncNotifier<List<TransactionDbModel>>
    implements TransactionStorage {
  @override
  FutureOr<List<TransactionDbModel>> build() async {
    final storage = await ref.watch(storageProvider.future);

    // Use the storage-backed provider to avoid circular dependency with storedWalletsProvider
    final walletId = await ref.watch(currentWalletIdProvider.future);
    if (walletId == null) {
      return [];
    }

    final transactions = await storage.transactionDbModels
        .filter()
        .walletIdEqualTo(walletId)
        .findAll();

    return transactions;
  }

  /// Helper method to reload transactions for the current wallet only
  Future<void> _reloadCurrentWalletTransactions() async {
    final storage = await ref.read(storageProvider.future);
    final walletId =
        await ref.read(storedWalletsProvider.notifier).getCurrentWalletId();

    if (walletId != null) {
      final updated = await storage.transactionDbModels
          .filter()
          .walletIdEqualTo(walletId)
          .findAll();
      state = AsyncValue.data(updated);
    } else {
      state = const AsyncValue.data([]);
    }
  }

  @override
  Future<void> save(TransactionDbModel model) async {
    try {
      final storage = await ref.read(storageProvider.future);

      final walletId =
          await ref.read(storedWalletsProvider.notifier).getCurrentWalletId();
      if (walletId == null) {
        throw Exception('No active wallet');
      }

      TransactionDbModel item = !model.isPeg
          ? model
          : model.copyWith(
              receiveAddress: ref.read(sideswapReceiveAddressCacheProvider));

      if (model.isPeg == true && model.receiveAddress?.isEmpty == true) {
        throw Exception('Invalid receive address');
      }

      if (item.isUSDtSwap &&
          item.swapServiceSource == null &&
          item.serviceOrderId != null) {
        final swapOrder = await ref
            .read(swapStorageProvider.notifier)
            .getOrderById(item.serviceOrderId!);
        if (swapOrder != null) {
          item = item.copyWith(swapServiceSource: swapOrder.serviceType);
        }
      }

      _logger.debug('Saving transaction: $item');

      await storage.writeTxn(() => storage.transactionDbModels.put(
            item.copyWith(walletId: walletId),
          ));

      // Reload current wallet's transactions
      await _reloadCurrentWalletTransactions();
    } catch (e, st) {
      _logger.error('Error saving transaction', e, st);
      rethrow;
    } finally {
      ref.read(sideswapReceiveAddressCacheProvider.notifier).clear();
    }
  }

  @override
  Future<void> clear() async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() => storage.transactionDbModels.clear());
    await _reloadCurrentWalletTransactions();
  }

  @override
  Future<void> clearByWalletId(String walletId) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      final count = await storage.transactionDbModels
          .filter()
          .walletIdEqualTo(walletId)
          .deleteAll();
      _logger.debug('Removed $count transactions for wallet $walletId');
    });
    await _reloadCurrentWalletTransactions();
  }

  @override
  Future<void> clearGhostTransactions() async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      final ghostTxns = await storage.transactionDbModels
          .filter()
          .isGhostEqualTo(true)
          .findAll();
      _logger.debug('Removing Ghost Txns: ${ghostTxns.length}');
      Future.wait(ghostTxns.map((txn) {
        return storage.transactionDbModels.delete(txn.id);
      }));
    });
  }

  @override
  Future<void> updateTxHash({
    required String serviceOrderId,
    required String newTxHash,
  }) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      final transaction = await storage.transactionDbModels
          .filter()
          .serviceOrderIdEqualTo(serviceOrderId)
          .findFirst();
      if (transaction != null) {
        final updated = transaction.copyWith(txhash: newTxHash);
        await storage.transactionDbModels.put(updated);
      }
    });

    await _reloadCurrentWalletTransactions();
  }

  //ANCHOR: Boltz-related convenience methods
  @override
  Future<void> updateReceiveAddressForBoltzId({
    required String boltzId,
    required String newReceiveAddress,
  }) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      final transaction = await storage.transactionDbModels
          .filter()
          .serviceOrderIdEqualTo(boltzId)
          .findFirst();
      if (transaction != null) {
        final updated = transaction.copyWith(receiveAddress: newReceiveAddress);
        await storage.transactionDbModels.put(updated);
      }
    });

    await _reloadCurrentWalletTransactions();
  }

  @override
  Future<void> markBoltzGhostTxn(String id, {int? amount, int? fee}) async {
    final storage = await ref.read(storageProvider.future);
    final transaction = await storage.transactionDbModels
        .filter()
        .serviceOrderIdEqualTo(id)
        .findFirst();
    _logger.debug('Marking Boltz transaction: $transaction');
    if (transaction != null) {
      await ref
          .read(transactionStorageProvider.notifier)
          .save(transaction.copyWith(
            isGhost: true,
            ghostTxnCreatedAt: DateTime.now(),
            ghostTxnAmount: amount,
            ghostTxnFee: fee,
          ));
    }
  }

  @override
  Future<void> saveBoltzRefundTxn({
    required LbtcLnSwap boltzSwap,
    required String txId,
  }) async {
    final storage = await ref.read(storageProvider.future);
    final transaction = await storage.transactionDbModels
        .filter()
        .serviceOrderIdEqualTo(boltzSwap.id)
        .findFirst();
    _logger.debug('Marking Boltz transaction as failed: $transaction');
    if (transaction != null) {
      await ref
          .read(transactionStorageProvider.notifier)
          .save(transaction.copyWith(
            type: TransactionDbModelType.boltzSendFailed,
          ));
    }
    TransactionDbModel refundTransactionDbModel = TransactionDbModel(
      txhash: txId,
      assetId: boltzSwap.network.name,
      type: TransactionDbModelType.boltzRefund,
      isGhost: true,
      ghostTxnCreatedAt: DateTime.now(),
      ghostTxnAmount: boltzSwap.outAmount.toInt(),
      serviceOrderId: boltzSwap.id,
    );
    await ref
        .read(transactionStorageProvider.notifier)
        .save(refundTransactionDbModel);
  }

  @override
  Future<void> updateReverseSwapClaim({
    required String boltzId,
    required String claimTxId,
    required String receiveAddress,
    required int outAmount,
    required int fee,
  }) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      final transaction = await storage.transactionDbModels
          .filter()
          .serviceOrderIdEqualTo(boltzId)
          .findFirst();
      if (transaction == null) {
        logger.warning(
            '[Transactions] No transaction found for Boltz ID: $boltzId');
        return;
      }

      final updated = transaction.copyWith(
        txhash: claimTxId,
        receiveAddress: receiveAddress,
        isGhost: true,
        ghostTxnCreatedAt: DateTime.now(),
        ghostTxnAmount: outAmount,
        ghostTxnFee: fee,
      );
      await storage.transactionDbModels.put(updated);
    });

    await _reloadCurrentWalletTransactions();
  }

  @override
  Future<void> updateTransactionNote({
    required String txHash,
    required String note,
  }) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      final transaction = await storage.transactionDbModels
          .filter()
          .txhashEqualTo(txHash)
          .findFirst();

      if (transaction == null) {
        logger.warning(
            '[Transactions] No DB transaction found for TX ID: $txHash. Creating one.');
        final transaction = TransactionDbModel(txhash: txHash, note: note);
        return await storage.transactionDbModels.put(transaction);
      }

      final updated = transaction.copyWith(note: note);
      await storage.transactionDbModels.put(updated);
    });

    await _reloadCurrentWalletTransactions();
  }

  //ANCHOR: Clear
  @override
  Future<void> clearFromMemory() async {
    state = const AsyncValue.data([]);
  }

  Future<bool> addTransactionForCurrentWallet(
      TransactionDbModel transaction) async {
    try {
      final storage = await ref.watch(storageProvider.future);
      final walletId =
          await ref.read(storedWalletsProvider.notifier).getCurrentWalletId();

      if (walletId != null) {
        // For multi-wallet, always set the wallet ID
        transaction = transaction.copyWith(walletId: walletId);
      }

      await storage.transactionDbModels.put(transaction);
      ref.invalidateSelf();
      return true;
    } catch (e, stack) {
      _logger.error('Error adding transaction: $e\n$stack');
      return false;
    }
  }
}
