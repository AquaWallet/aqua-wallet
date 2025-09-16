import 'dart:async';

import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';
import 'package:isar/isar.dart';
import 'package:coin_cz/features/sideshift/sideshift.dart';

final _logger = CustomLogger(FeatureFlag.sideshiftOrderStorage);

const kSideshiftBoxName = 'sideshift';

//ANCHOR - Public-facing Sideshift Orders Storage Notifier

final sideshiftStorageProvider = AsyncNotifierProvider<
    SideshiftOrderStorageNotifier,
    List<SideshiftOrderDbModel>>(SideshiftOrderStorageNotifier.new);

abstract class SideshiftOrderStorage {
  Future<void> save(SideshiftOrderDbModel model);
  Future<void> delete(String orderId);
  Future<void> updateOrder({
    required String orderId,
    String? txHash,
    SideshiftOrderStatus? status,
  });
  Future<void> clear();
}

class SideshiftOrderStorageNotifier
    extends AsyncNotifier<List<SideshiftOrderDbModel>>
    implements SideshiftOrderStorage {
  @override
  FutureOr<List<SideshiftOrderDbModel>> build() async {
    try {
      final storage = await ref.watch(storageProvider.future);
      return storage.sideshiftOrderDbModels.all().sortByCreated();
    } catch (e, st) {
      _logger.error('Error building orders list', e, st);
      return [];
    }
  }

  @override
  Future<void> save(SideshiftOrderDbModel model) async {
    try {
      final storage = await ref.read(storageProvider.future);
      await storage.writeTxn(() async {
        final existing = await storage.sideshiftOrderDbModels
            .where()
            .orderIdEqualTo(model.orderId)
            .findFirst();
        if (existing != null) {
          final updated = model.copyWith(id: existing.id);
          storage.sideshiftOrderDbModels.put(updated);
        } else {
          storage.sideshiftOrderDbModels.put(model);
        }
      });

      final update = await storage.sideshiftOrderDbModels.all().sortByCreated();
      state = AsyncValue.data(update);
    } catch (e, st) {
      _logger.error('Error saving transaction', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateOrder({
    required String orderId,
    String? txHash,
    SideshiftOrderStatus? status,
  }) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      var model = await storage.sideshiftOrderDbModels
          .where()
          .orderIdEqualTo(orderId)
          .findFirst();

      if (model == null) {
        _logger.info('Order not found: $orderId');
        return;
      }

      if (txHash != null) {
        model = model.copyWith(onchainTxHash: txHash);
      }

      if (status != null) {
        model = model.copyWith(status: status);
      }

      await storage.sideshiftOrderDbModels.put(model);
    });

    final updated = await storage.sideshiftOrderDbModels.all().sortByCreated();
    state = AsyncValue.data(updated);
  }

  @override
  Future<void> clear() async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() => storage.clear());

    final updated = await storage.sideshiftOrderDbModels.all().sortByCreated();
    state = AsyncValue.data(updated);
  }

  @override
  Future<void> delete(String orderId) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      storage.sideshiftOrderDbModels
          .where()
          .orderIdEqualTo(orderId)
          .deleteAll();
    });
  }
}
