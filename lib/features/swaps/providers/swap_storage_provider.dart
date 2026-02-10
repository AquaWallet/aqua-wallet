import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/wallet/wallet.dart';
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

  // Pagination
  Future<List<SwapOrderDbModel>> getOrdersPaginated({
    required List<SwapOrderStatus> statuses,
    required int offset,
    required int limit,
    String? searchQuery,
  });

  Future<void> clear();
}

class SwapOrderStorageNotifier extends AsyncNotifier<List<SwapOrderDbModel>>
    implements SwapOrderStorage {
  Future<({Isar storage, String walletId})> _requireWallet() async {
    final storage = await ref.read(storageProvider.future);
    final walletId =
        await ref.read(storedWalletsProvider.notifier).getCurrentWalletId();
    if (walletId == null) throw const NoActiveWalletException();
    return (storage: storage, walletId: walletId);
  }

  Future<({Isar storage, String walletId})?> _getStorageWithWallet() async {
    final storage = await ref.read(storageProvider.future);
    final walletId =
        await ref.read(storedWalletsProvider.notifier).getCurrentWalletId();
    if (walletId == null) return null;
    return (storage: storage, walletId: walletId);
  }

  @override
  FutureOr<List<SwapOrderDbModel>> build() async {
    try {
      final storage = await ref.watch(storageProvider.future);
      final currentWallet = ref.watch(
        storedWalletsProvider.select((s) => s.valueOrNull?.currentWallet),
      );
      final walletId = currentWallet?.id;
      if (walletId == null) {
        return [];
      }
      return storage.swapOrderDbModels
          .filter()
          .walletIdEqualTo(walletId)
          .sortByCreatedAt()
          .findAll();
    } catch (e, st) {
      _logger.error('Error building orders list', e, st);
      return [];
    }
  }

  Future<void> _reloadCurrentWalletOrders() async {
    final walletStorage = await _getStorageWithWallet();
    if (walletStorage == null) {
      state = const AsyncValue.data([]);
      return;
    }
    final orders = await walletStorage.storage.swapOrderDbModels
        .filter()
        .walletIdEqualTo(walletStorage.walletId)
        .sortByCreatedAt()
        .findAll();
    state = AsyncValue.data(orders);
  }

  @override
  Future<SwapOrderDbModel?> getOrderById(String orderId) async {
    try {
      final walletStorage = await _getStorageWithWallet();
      if (walletStorage == null) return null;
      return await walletStorage.storage.swapOrderDbModels
          .filter()
          .walletIdEqualTo(walletStorage.walletId)
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
      final (:storage, :walletId) = await _requireWallet();

      await storage.writeTxn(() async {
        final existing = await storage.swapOrderDbModels
            .filter()
            .walletIdEqualTo(walletId)
            .orderIdEqualTo(model.orderId)
            .findFirst();
        if (existing != null) {
          final updated = model.copyWith(id: existing.id, walletId: walletId);
          storage.swapOrderDbModels.put(updated);
        } else {
          storage.swapOrderDbModels.put(model.copyWith(walletId: walletId));
        }
      });

      await _reloadCurrentWalletOrders();
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
    final (:storage, :walletId) = await _requireWallet();

    await storage.writeTxn(() async {
      var model = await storage.swapOrderDbModels
          .filter()
          .walletIdEqualTo(walletId)
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

    await _reloadCurrentWalletOrders();
  }

  @override
  Future<void> clear() async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() => storage.clear());

    await _reloadCurrentWalletOrders();
  }

  @override
  Future<void> delete(String orderId) async {
    final (:storage, :walletId) = await _requireWallet();

    await storage.writeTxn(() async {
      await storage.swapOrderDbModels
          .filter()
          .walletIdEqualTo(walletId)
          .orderIdEqualTo(orderId)
          .deleteAll();
    });
  }

  @override
  Future<List<SwapOrderDbModel>> getAllPendingSettlementSwaps() async {
    try {
      final walletStorage = await _getStorageWithWallet();
      if (walletStorage == null) return [];
      final walletSwaps = await walletStorage.storage.swapOrderDbModels
          .filter()
          .walletIdEqualTo(walletStorage.walletId)
          .findAll();
      final pendingSwaps =
          walletSwaps.where((swap) => swap.status.isPendingSettlement).toList();
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

  @override
  Future<List<SwapOrderDbModel>> getOrdersPaginated({
    required List<SwapOrderStatus> statuses,
    required int offset,
    required int limit,
    String? searchQuery,
  }) async {
    final walletStorage = await _getStorageWithWallet();
    if (walletStorage == null) return [];

    var query = walletStorage.storage.swapOrderDbModels
        .filter()
        .walletIdEqualTo(walletStorage.walletId);

    query = query.group((q) {
      var statusQuery = q.statusEqualTo(statuses.first);
      for (var i = 1; i < statuses.length; i++) {
        statusQuery = statusQuery.or().statusEqualTo(statuses[i]);
      }
      return statusQuery;
    });

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      query = query.group((q) => q
          .orderIdContains(lowerQuery, caseSensitive: false)
          .or()
          .fromAssetContains(lowerQuery, caseSensitive: false)
          .or()
          .toAssetContains(lowerQuery, caseSensitive: false)
          .or()
          .depositAddressContains(lowerQuery, caseSensitive: false)
          .or()
          .settleAddressContains(lowerQuery, caseSensitive: false));
    }

    // Apply sorting, offset, and limit (descending order - newest first)
    final results =
        await query.sortByCreatedAtDesc().offset(offset).limit(limit).findAll();

    return results;
  }
}
