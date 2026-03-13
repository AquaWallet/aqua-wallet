import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';
import 'package:isar/isar.dart';

final _logger = CustomLogger(FeatureFlag.sideswap);

const kPegBoxName = 'peg';

//TODO: Use SwapStorageProvider instead. Pegs should be under the main swap interface.
@Deprecated(
    'TODO: Use SwapStorageProvider instead. Pegs should be under the main swap interface.')
// This provider is deprecated. Pegs should be managed under the main swap interface,
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
  Future<void> clearByWalletId(String walletId);
  Future<List<PegOrderDbModel>> getPegInOrders();
  Future<List<PegOrderDbModel>> getPegOutOrders();
  Future<List<PegOrderDbModel>> getAllPegOrders();
  Future<PegOrderDbModel?> getOrderById(String orderId);
}

@Deprecated(
    'TODO:  Use SwapStorageProvider instead. Pegs should be under the main swap interface.')
// This notifier is deprecated. Pegs should be managed under the main swap interface.
class PegOrderStorageNotifier extends AsyncNotifier<List<PegOrderDbModel>>
    implements PegOrderStorage {
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
  FutureOr<List<PegOrderDbModel>> build() async {
    final storage = await ref.watch(storageProvider.future);
    final currentWallet = ref.watch(
      storedWalletsProvider.select((s) => s.valueOrNull?.currentWallet),
    );
    final walletId = currentWallet?.id;
    if (walletId == null) {
      return [];
    }
    final orders = await storage.pegOrderDbModels
        .filter()
        .walletIdEqualTo(walletId)
        .sortByCreatedAtDesc()
        .findAll();
    _logger.debug('[Sideswap][Isar] Loaded ${orders.length} peg orders');
    return orders;
  }

  Future<void> _reloadCurrentWalletOrders() async {
    final walletStorage = await _getStorageWithWallet();
    if (walletStorage == null) {
      state = const AsyncValue.data([]);
      return;
    }
    final orders = await walletStorage.storage.pegOrderDbModels
        .filter()
        .walletIdEqualTo(walletStorage.walletId)
        .sortByCreatedAtDesc()
        .findAll();
    state = AsyncValue.data(orders);
  }

  @override
  Future<void> save(PegOrderDbModel model) async {
    try {
      final (:storage, :walletId) = await _requireWallet();

      await storage.writeTxn(() async {
        await storage.pegOrderDbModels.put(model.copyWith(walletId: walletId));
      });
      _logger.debug('[Isar] Saved peg order: ${model.orderId}');
      await _reloadCurrentWalletOrders();
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
    final (:storage, :walletId) = await _requireWallet();

    await storage.writeTxn(() async {
      final model = await storage.pegOrderDbModels
          .filter()
          .walletIdEqualTo(walletId)
          .orderIdEqualTo(orderId)
          .findFirst();

      if (model != null) {
        final updatedModel = model.copyWithStatus(status);
        await storage.pegOrderDbModels.put(updatedModel);
        _logger.debug('[Isar] Updated status for peg order: $orderId');
      } else {
        _logger.warning('[Isar] Order not found for update: $orderId');
      }
    });
    await _reloadCurrentWalletOrders();
  }

  @override
  Future<void> clear() async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() => storage.pegOrderDbModels.clear());
    await _reloadCurrentWalletOrders();
  }

  @override
  Future<void> clearByWalletId(String walletId) async {
    final storage = await ref.read(storageProvider.future);
    await storage.writeTxn(() async {
      final orders = await storage.pegOrderDbModels
          .filter()
          .walletIdEqualTo(walletId)
          .deleteAll();
      _logger.debug('Removing peg orders for wallet $walletId: $orders');
    });
    await _reloadCurrentWalletOrders();
  }

  @override
  Future<void> delete(String orderId) async {
    final (:storage, :walletId) = await _requireWallet();

    await storage.writeTxn(() async {
      final deletedCount = await storage.pegOrderDbModels
          .filter()
          .walletIdEqualTo(walletId)
          .orderIdEqualTo(orderId)
          .deleteAll();
      _logger
          .debug('[Isar] Deleted peg order: $orderId (Count: $deletedCount)');
    });
    await _reloadCurrentWalletOrders();
  }

  @override
  Future<List<PegOrderDbModel>> getPegInOrders() async {
    final walletStorage = await _getStorageWithWallet();
    if (walletStorage == null) return [];
    return walletStorage.storage.pegOrderDbModels
        .filter()
        .walletIdEqualTo(walletStorage.walletId)
        .isPegInEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Future<List<PegOrderDbModel>> getPegOutOrders() async {
    final walletStorage = await _getStorageWithWallet();
    if (walletStorage == null) return [];
    return walletStorage.storage.pegOrderDbModels
        .filter()
        .walletIdEqualTo(walletStorage.walletId)
        .isPegInEqualTo(false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Future<PegOrderDbModel?> getOrderById(String orderId) async {
    final walletStorage = await _getStorageWithWallet();
    if (walletStorage == null) return null;
    final order = await walletStorage.storage.pegOrderDbModels
        .filter()
        .walletIdEqualTo(walletStorage.walletId)
        .orderIdEqualTo(orderId)
        .findFirst();
    _logger.debug(
        '[Isar] Retrieved peg order: $orderId (Found: ${order != null})');
    return order;
  }

  @override
  Future<List<PegOrderDbModel>> getAllPegOrders() async {
    try {
      final walletStorage = await _getStorageWithWallet();
      if (walletStorage == null) return [];
      final allOrders = await walletStorage.storage.pegOrderDbModels
          .filter()
          .walletIdEqualTo(walletStorage.walletId)
          .findAll();
      _logger.debug('[Isar] Retrieved all peg orders: ${allOrders.length}');
      return allOrders;
    } catch (e, st) {
      _logger.error('[Isar] Error retrieving all peg orders', e, st);
      rethrow;
    }
  }

  Future<List<PegOrderDbModel>> getAllPendingSettlementPegOrders() async {
    try {
      final walletStorage = await _getStorageWithWallet();
      if (walletStorage == null) return [];
      final allOrders = await walletStorage.storage.pegOrderDbModels
          .filter()
          .walletIdEqualTo(walletStorage.walletId)
          .findAll();
      final pendingOrders = allOrders.where((order) {
        final consolidatedStatus = order.status.getConsolidatedStatus();
        return PegStatusState(consolidatedStatus: consolidatedStatus)
            .isPendingSettlement;
      }).toList();
      _logger.debug(
          '[Peg Storage] Retrieved ${pendingOrders.length} pending peg orders');
      return pendingOrders;
    } catch (e, st) {
      _logger.error('[Peg Storage] Error retrieving pending peg orders', e, st);
      return [];
    }
  }

  Future<bool> isOrderPending(String orderId) async {
    final order = await getOrderById(orderId);
    if (order == null) {
      _logger.info('Order not found: $orderId');
      return false;
    }

    return order.isPendingConfirmations;
  }
}

extension PegOrderMatchingX on List<PegOrderDbModel> {
  // Finds a peg order matching the given transaction.
  //
  // Matches by:
  // 1. Direct txhash match
  // 2. For L-BTC peg-ins: matches by receiveAddress since the L-BTC transaction
  //    has a different txhash than the BTC deposit transaction
  // 3. For BTC peg-outs: matches incoming BTC by receiveAddress since the BTC
  //    incoming transaction is separate from the L-BTC outgoing transaction
  PegOrderDbModel? findMatchingOrder({
    required String transactionId,
    required Asset asset,
    List<GdkTransactionInOut>? outputs,
  }) {
    return firstWhereOrNull((p) {
      if (p.txhash == transactionId) return true;

      // For L-BTC peg-ins, match the incoming L-BTC by receiveAddress
      final isLbtcPegIn = asset.isLBTC && p.isPegIn && p.receiveAddress != null;
      if (isLbtcPegIn && outputs != null) {
        final outputAddresses = outputs.map((o) => o.address).nonNulls;
        return outputAddresses.contains(p.receiveAddress);
      }

      // For BTC peg-outs, match the incoming BTC by receiveAddress
      final isBtcPegOut = asset.isBTC && !p.isPegIn && p.receiveAddress != null;
      if (isBtcPegOut && outputs != null) {
        final relevantOutputAddresses = outputs
            .where((o) => o.isRelevant == true)
            .map((o) => o.address)
            .nonNulls;
        return relevantOutputAddresses.contains(p.receiveAddress);
      }

      return false;
    });
  }
}
