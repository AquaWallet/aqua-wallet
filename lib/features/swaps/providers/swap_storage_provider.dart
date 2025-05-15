import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';
import 'package:isar/isar.dart';

final _logger = CustomLogger(FeatureFlag.swapOrderStorage);

const kSwapBoxName = 'swap';

final swapStorageProvider =
    AsyncNotifierProvider<SwapOrderStorageNotifier, List<SwapOrderDbModel>>(
        SwapOrderStorageNotifier.new);

abstract class SwapOrderStorage {
  Future<SwapOrderDbModel?> getOrderById(String orderId);
  Future<void> save(SwapOrderDbModel model);
  Future<void> delete(String orderId);
  Future<void> updateOrder({
    required String orderId,
    String? txHash,
    SwapOrderStatus? status,
  });

  // Pending Swaps
  Future<List<SwapOrderDbModel>> getAllPendingSettlementSwaps();
  Future<List<SwapOrderDbModel>> getPendingSettlementSwapsForService(
      SwapServiceSource service);
  Future<List<SwapOrderDbModel>> getPendingSettlementSwapsForAssets({
    Asset? depositAsset,
    Asset? settleAsset,
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
  Future<SwapOrderDbModel?> getOrderById(String orderId) async {
    try {
      final storage = await ref.read(storageProvider.future);
      return await storage.swapOrderDbModels
          .where()
          .orderIdEqualTo(orderId)
          .findFirst();
    } catch (e, st) {
      _logger.error('Error fetching order by ID: $orderId', e, st);
      return null;
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

  @override
  Future<List<SwapOrderDbModel>> getAllPendingSettlementSwaps() async {
    try {
      final storage = await ref.read(storageProvider.future);
      final allSwaps = await storage.swapOrderDbModels.all();
      final pendingSwaps =
          allSwaps.where((swap) => swap.status.isPendingSettlement).toList();
      return pendingSwaps;
    } catch (e, st) {
      _logger.error('Error fetching pending swaps', e, st);
      return [];
    }
  }

  @override
  Future<List<SwapOrderDbModel>> getPendingSettlementSwapsForService(
      SwapServiceSource service) async {
    try {
      final pendingSwaps = await getAllPendingSettlementSwaps();
      final serviceSwaps =
          pendingSwaps.where((swap) => swap.serviceType == service).toList();
      _logger.debug(
          '[Pending Swaps] Fetched ${serviceSwaps.length} pending swaps for service: $service');
      return serviceSwaps;
    } catch (e, st) {
      _logger.error('Error fetching pending swaps for service', e, st);
      return [];
    }
  }

  /// Fetches pending settlement swaps filtered by optional deposit and settle assets.
  ///
  /// If [depositAsset] is provided, only swaps where the deposit asset matches
  /// will be included. If [settleAsset] is provided, only swaps where the settle
  /// asset matches will be included. If neither is provided, all pending settlement
  /// swaps are returned.
  ///
  /// Returns a list of [SwapOrderDbModel] that match the specified criteria.
  @override
  Future<List<SwapOrderDbModel>> getPendingSettlementSwapsForAssets({
    Asset? depositAsset,
    Asset? settleAsset,
  }) async {
    try {
      final pendingSwaps = await getAllPendingSettlementSwaps();
      final assetSwaps = pendingSwaps.where((swap) {
        final fromAsset = SwapAssetExt.fromId(swap.fromAsset);
        final toAsset = SwapAssetExt.fromId(swap.toAsset);

        // Check if the swap's fromAsset matches the depositAsset, if provided.
        final matchesDepositAsset =
            depositAsset == null || fromAsset.id == depositAsset.id;

        // Check if the swap's toAsset matches the settleAsset, if provided.
        final matchesSettleAsset =
            settleAsset == null || toAsset.id == settleAsset.id;

        return matchesDepositAsset && matchesSettleAsset;
      }).toList();

      _logger.debug(
          '[Pending Swaps] Fetched ${assetSwaps.length} pending swaps for assets: '
          'depositAsset=${depositAsset?.id}, settleAsset=${settleAsset?.id}');
      return assetSwaps;
    } catch (e, st) {
      _logger.error('Error fetching pending swaps for assets', e, st);
      return [];
    }
  }
}
