import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:isar/isar.dart';

final _logger = CustomLogger(FeatureFlag.sideswap);

const kPegBoxName = 'peg';

final pegStorageProvider =
    AsyncNotifierProvider<PegOrderStorageNotifier, List<PegOrderDbModel>>(
        PegOrderStorageNotifier.new);

abstract class PegOrderStorage {
  Future<void> save(PegOrderDbModel model);
  Future<void> delete(String orderId);
  Future<void> updateOrderStatus({
    required String orderId,
    required SwapPegStatusResult status,
  });
  Future<void> clear();
  Future<List<PegOrderDbModel>> getPegInOrders();
  Future<List<PegOrderDbModel>> getPegOutOrders();
  Future<PegOrderDbModel?> getOrderById(String orderId);
}

class PegOrderStorageNotifier extends AsyncNotifier<List<PegOrderDbModel>>
    implements PegOrderStorage {
  @override
  FutureOr<List<PegOrderDbModel>> build() async {
    final storage = await ref.watch(storageProvider.future);
    final orders =
        await storage.pegOrderDbModels.where().sortByCreatedAtDesc().findAll();
    _logger.debug('[Sideswap][Isar] Loaded ${orders.length} peg orders');
    return orders;
  }

  @override
  Future<void> save(PegOrderDbModel model) async {
    try {
      final storage = await ref.read(storageProvider.future);
      await storage.writeTxn(() async {
        await storage.pegOrderDbModels.put(model);
      });
      _logger.debug('[Isar] Saved peg order: ${model.orderId}');
      state = AsyncValue.data([...state.value ?? [], model]);
    } catch (e, st) {
      _logger.error('[Isar] Error saving peg order', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required SwapPegStatusResult status,
  }) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      final model = await storage.pegOrderDbModels
          .where()
          .orderIdEqualTo(orderId)
          .findFirst();

      if (model != null) {
        final updatedModel = model.copyWithStatus(status);
        await storage.pegOrderDbModels.put(updatedModel);
        _logger.debug('[Isar] Updated status for peg order: $orderId');
        state = AsyncValue.data(state.value
                ?.map(
                    (order) => order.orderId == orderId ? updatedModel : order)
                .toList() ??
            []);
      } else {
        _logger.warning('[Isar] Order not found for update: $orderId');
      }
    });
  }

  @override
  Future<void> clear() async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() => storage.pegOrderDbModels.clear());
    state = const AsyncValue.data([]);
  }

  @override
  Future<void> delete(String orderId) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      final deletedCount = await storage.pegOrderDbModels
          .where()
          .orderIdEqualTo(orderId)
          .deleteAll();
      _logger
          .debug('[Isar] Deleted peg order: $orderId (Count: $deletedCount)');
    });
    state = AsyncValue.data(
        state.value?.where((order) => order.orderId != orderId).toList() ?? []);
  }

  @override
  Future<List<PegOrderDbModel>> getPegInOrders() async {
    final storage = await ref.read(storageProvider.future);
    return storage.pegOrderDbModels
        .where()
        .isPegInEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Future<List<PegOrderDbModel>> getPegOutOrders() async {
    final storage = await ref.read(storageProvider.future);
    return storage.pegOrderDbModels
        .where()
        .isPegInEqualTo(false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Future<PegOrderDbModel?> getOrderById(String orderId) async {
    final storage = await ref.read(storageProvider.future);
    final order = await storage.pegOrderDbModels
        .where()
        .orderIdEqualTo(orderId)
        .findFirst();
    _logger.debug(
        '[Isar] Retrieved peg order: $orderId (Found: ${order != null})');
    return order;
  }
}
