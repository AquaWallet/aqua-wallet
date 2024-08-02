import 'dart:async';
import 'dart:convert';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _orderPrefix = 'sideshiftOrder_';
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
    OrderStatus? status,
  });
  Future<void> clear();
}

class SideshiftOrderStorageNotifier
    extends AsyncNotifier<List<SideshiftOrderDbModel>>
    implements SideshiftOrderStorage {
  @override
  FutureOr<List<SideshiftOrderDbModel>> build() async {
    // NOTE: This is a one-time migration
    _migrateFromSharedPreferencesToIsar();

    final storage = await ref.watch(storageProvider.future);
    return storage.sideshiftOrderDbModels.all().sortByCreated();
  }

  Future<void> _migrateFromSharedPreferencesToIsar() async {
    final prefs = await SharedPreferences.getInstance();
    final toMigrate = prefs.getKeys().where((k) => k.startsWith(_orderPrefix));

    if (toMigrate.isNotEmpty) {
      logger.d('[SideshiftStorage] Migrating ${toMigrate.length} to Isar');
    }

    for (String key in toMigrate) {
      String? json = prefs.getString(key);
      if (json != null) {
        final order = SideshiftOrderStatusResponse.fromJson(jsonDecode(json));

        logger
            .d("[SideshiftStorage] Migrating order to secure storage: $order");

        await ref
            .read(transactionStorageProvider.notifier)
            .save(TransactionDbModel.fromSideshiftOrder(order));
        await ref
            .read(sideshiftStorageProvider.notifier)
            .save(SideshiftOrderDbModel.fromSideshiftOrderResponse(order));

        prefs.remove(key);
        logger.d(
            "[SideshiftStorage] Migrated order to secure storage: ${order.id}");
      }
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
      logger.e('[SideshiftStorage] Error saving transaction', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateOrder({
    required String orderId,
    String? txHash,
    OrderStatus? status,
  }) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      var model = await storage.sideshiftOrderDbModels
          .where()
          .orderIdEqualTo(orderId)
          .findFirst();

      if (model == null) {
        logger.i('[SideshiftOrderStorage] Order not found: $orderId');
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
