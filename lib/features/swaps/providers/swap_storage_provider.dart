import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';
import 'package:isar/isar.dart';

final _logger = CustomLogger(FeatureFlag.swapOrderStorage);

const kSwapBoxName = 'swap';

final swapStorageProvider =
    AsyncNotifierProvider<SwapOrderStorageNotifier, List<SwapOrderDbModel>>(
        SwapOrderStorageNotifier.new);

abstract class SwapOrderStorage {
  Future<void> save(SwapOrderDbModel model);
  Future<void> delete(String orderId);
  Future<void> updateOrder({
    required String orderId,
    String? txHash,
    SwapOrderStatus? status,
  });
  Future<void> clear();
}

class SwapOrderStorageNotifier extends AsyncNotifier<List<SwapOrderDbModel>>
    implements SwapOrderStorage {
  @override
  FutureOr<List<SwapOrderDbModel>> build() async {
    try {
      final storage = await ref.watch(storageProvider.future);
      return storage.swapOrderDbModels.where().sortByCreatedAt().findAll();
    } catch (e, st) {
      _logger.error('Error building orders list', e, st);
      return [];
    }
  }

  @override
  Future<void> save(SwapOrderDbModel model) async {
    try {
      final storage = await ref.read(storageProvider.future);
      await storage.writeTxn(() async {
        final existing = await storage.swapOrderDbModels
            .where()
            .orderIdEqualTo(model.orderId)
            .findFirst();
        if (existing != null) {
          final updated = model.copyWith(id: existing.id);
          storage.swapOrderDbModels.put(updated);
        } else {
          storage.swapOrderDbModels.put(model);
        }
      });

      final update =
          await storage.swapOrderDbModels.where().sortByCreatedAt().findAll();
      state = AsyncValue.data(update);
    } catch (e, st) {
      _logger.error('Error saving order', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateOrder({
    required String orderId,
    String? txHash,
    SwapOrderStatus? status,
  }) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      var model = await storage.swapOrderDbModels
          .where()
          .orderIdEqualTo(orderId)
          .findFirst();

      if (model == null) {
        _logger.info('Order not found: $orderId', FeatureFlag.swapOrderStorage);
        return;
      }

      if (txHash != null) {
        model = model.copyWith(onchainTxHash: txHash);
      }

      if (status != null) {
        model = model.copyWith(status: status);
      }

      await storage.swapOrderDbModels.put(model);
    });

    final updated = await storage.swapOrderDbModels.all().sortByCreatedAt();
    state = AsyncValue.data(updated);
  }

  @override
  Future<void> clear() async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() => storage.clear());

    final updated = await storage.swapOrderDbModels.all().sortByCreatedAt();
    state = AsyncValue.data(updated);
  }

  @override
  Future<void> delete(String orderId) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      storage.swapOrderDbModels.where().orderIdEqualTo(orderId).deleteAll();
    });
  }
}
