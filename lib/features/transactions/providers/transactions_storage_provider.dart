import 'dart:async';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

const kTransactionBoxName = 'transactions';

//ANCHOR - Isar Storage

final _storageProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = Isar.getInstance() ??
      await Isar.open(
        [TransactionDbModelSchema],
        directory: dir.path,
      );
  ref.onDispose(isar.close);
  return isar;
});

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
}

class TransactionStorageNotifier extends AsyncNotifier<List<TransactionDbModel>>
    implements TransactionStorage {
  @override
  FutureOr<List<TransactionDbModel>> build() async {
    final storage = await ref.watch(_storageProvider.future);
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

      final storage = await ref.read(_storageProvider.future);
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
    final storage = await ref.read(_storageProvider.future);
    await storage.writeTxn(() => storage.clear());
    state = AsyncValue.data(await storage.transactionDbModels.all());
  }
}
