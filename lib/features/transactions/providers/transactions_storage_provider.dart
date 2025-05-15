import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:boltz_dart/boltz_dart.dart';
import 'package:isar/isar.dart';

final _logger = CustomLogger(FeatureFlag.transactionStorage);

const kTransactionBoxName = 'transactions';

//ANCHOR - Address Cache

final _sideswapReceiveAddressCacheProvider =
    StateNotifierProvider<_AddressCacheNotifier, String>(
        (_) => _AddressCacheNotifier());

//NOTE - This intermediary cache is needed because swap and peg operations are
//disjointed. The swap request is sent to sideswap and the rest of the flow is
//handled asynchronously upon websocket response from sideswap, which does not
//include the receive address.
class _AddressCacheNotifier extends StateNotifier<String> {
  _AddressCacheNotifier() : super('');

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
  Future<void> clearGhostTransactions();
  void cacheSideswapReceiveAddress(String address);
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
}

class TransactionStorageNotifier extends AsyncNotifier<List<TransactionDbModel>>
    implements TransactionStorage {
  @override
  FutureOr<List<TransactionDbModel>> build() async {
    final storage = await ref.watch(storageProvider.future);
    final transactions = await storage.transactionDbModels.all();
    return transactions;
  }

  @override
  void cacheSideswapReceiveAddress(String address) {
    _logger.debug('Caching address: $address');
    ref.read(_sideswapReceiveAddressCacheProvider.notifier).set(address);
  }

  @override
  Future<void> save(TransactionDbModel model) async {
    try {
      final address = ref.read(_sideswapReceiveAddressCacheProvider);
      if (model.isPeg && address.isEmpty) {
        throw Exception('Invalid receive address');
      }

      final item = model.copyWith(receiveAddress: address);
      _logger.debug('Saving transaction: $item');

      final storage = await ref.read(storageProvider.future);
      await storage.writeTxn(() => storage.transactionDbModels.put(item));
      final updated = await storage.transactionDbModels.all();
      state = AsyncValue.data(updated);
    } catch (e, st) {
      _logger.error('Error saving transaction', e, st);
      rethrow;
    } finally {
      ref.read(_sideswapReceiveAddressCacheProvider.notifier).clear();
    }
  }

  @override
  Future<void> clear() async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() => storage.clear());
    state = AsyncValue.data(await storage.transactionDbModels.all());
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

    final updated = await storage.transactionDbModels.all();
    state = AsyncValue.data(updated);
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

    final updated = await storage.transactionDbModels.all();
    state = AsyncValue.data(updated);
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
      ghostTxnAmount: boltzSwap.outAmount,
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

    final updated = await storage.transactionDbModels.all();
    state = AsyncValue.data(updated);
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

    final updated = await storage.transactionDbModels.all();
    state = AsyncValue.data(updated);
  }
}
