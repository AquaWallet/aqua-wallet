import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:isar/isar.dart';

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
  void cacheSideswapReceiveAddress(String address);
  Future<void> updateTxHash({
    required String serviceOrderId,
    required String newTxHash,
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
    logger.d('[TransactionStorage] Caching address: $address');
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
      logger.d('[TransactionStorage] Saving transaction: $item');

      final storage = await ref.read(storageProvider.future);
      await storage.writeTxn(() => storage.transactionDbModels.put(item));
      final updated = await storage.transactionDbModels.all();
      state = AsyncValue.data(updated);
    } catch (e, st) {
      logger.e('[TransactionStorage] Error saving transaction', e, st);
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
}
