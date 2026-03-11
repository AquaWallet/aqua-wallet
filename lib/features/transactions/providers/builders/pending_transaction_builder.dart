import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingTransactionUiModelsProvider = Provider.autoDispose((ref) {
  return PendingTransactionUiModelsBuilder(
    strategyFactory: ref.read(transactionUiModelsFactoryProvider),
    confirmationService: ref.read(confirmationServiceProvider),
    swapStorage: ref.read(swapStorageProvider.notifier),
    pegStorage: ref.read(pegStorageProvider.notifier),
    boltzSwaps: ref.watch(boltzStorageProvider).valueOrNull ?? [],
  );
});

// Responsible for building pending transaction UI models.
//
// This builder processes pending transactions (swap/peg orders, ghost
// transactions and transactions with not enough confirmations) and builds their
// UI models.
class PendingTransactionUiModelsBuilder implements TransactionUiModelBuilder {
  const PendingTransactionUiModelsBuilder({
    required this.confirmationService,
    required this.swapStorage,
    required this.pegStorage,
    required this.strategyFactory,
    required this.boltzSwaps,
  });

  final ConfirmationService confirmationService;
  final SwapOrderStorageNotifier swapStorage;
  final PegOrderStorageNotifier pegStorage;
  final TransactionStrategyFactory strategyFactory;
  final List<BoltzSwapDbModel> boltzSwaps;

  // Grace period for terminal Boltz orders to ensure we don't hide recently completed transactions
  static const _gracePeriod = Duration(days: 1);

  @override
  Future<List<TransactionUiModel>> build(TransactionBuilderArgs args) async {
    final pendingDbTxns = await _collectPendingTransactions(
      asset: args.asset,
      networkTxns: args.networkTxns,
      localDbTxns: args.localDbTxns,
    );
    final dbTxnUiModels = _buildPendingDbTransactions(
      asset: args.asset,
      networkTxns: args.networkTxns,
      pendingTxns: pendingDbTxns,
      availableAssets: args.availableAssets,
    );
    final networkTxnUiModels = await _buildUnconfirmedNetworkTransactions(
      asset: args.asset,
      networkTxns: args.networkTxns,
      localDbTxns: args.localDbTxns,
      availableAssets: args.availableAssets,
      pendingTxns: pendingDbTxns,
    );

    return [...dbTxnUiModels, ...networkTxnUiModels];
  }

  // Collects pending TransactionDbModel instances from:
  // - Pending swap orders (converted from SwapOrderDbModel)
  // - Pending peg orders (converted from PegOrderDbModel)
  // - Ghost transactions that haven't been confirmed yet
  Future<List<TransactionDbModel>> _collectPendingTransactions({
    required Asset asset,
    required List<GdkTransaction> networkTxns,
    required List<TransactionDbModel> localDbTxns,
  }) async {
    final pendingTxns = <TransactionDbModel>[];
    final seenTxHashes = <String>{};
    final seenPegOrderIds = <String>{};

    // Fetch pending swap transactions
    final swapOrders = await swapStorage.getPendingSettlementSwapsForAssets(
        settleAsset: asset);
    for (final order in swapOrders) {
      final model = TransactionDbModel.fromSwapOrderDbModel(
        order,
        walletId: order.walletId ?? '',
      );
      pendingTxns.add(model);
      seenTxHashes.add(model.txhash);
    }

    // Fetch pending peg transactions (only for BTC and LBTC assets)
    if (asset.isBTC || asset.isLBTC) {
      final pegOrders = await pegStorage.getAllPendingSettlementPegOrders();

      for (final order in pegOrders) {
        final model = TransactionDbModel.fromPegOrderDbModel(
          order,
          walletId: order.walletId ?? '',
          isGhost: true,
        );

        // Deduplicate by both txhash and serviceOrderId for peg transactions
        // since txhash can be empty initially
        final hasSeenTxhash =
            model.txhash.isNotEmpty && seenTxHashes.contains(model.txhash);
        final hasSeenOrderId = model.serviceOrderId != null &&
            seenPegOrderIds.contains(model.serviceOrderId!);

        if (!hasSeenTxhash && !hasSeenOrderId) {
          pendingTxns.add(model);
          if (model.txhash.isNotEmpty) {
            seenTxHashes.add(model.txhash);
          }
          if (model.serviceOrderId != null) {
            seenPegOrderIds.add(model.serviceOrderId!);
          }
        }
      }
    }

    // Add ghost transactions that are still pending
    final ghostTxns = localDbTxns.where((t) => t.isGhost).toList();

    for (final ghostTxn in ghostTxns) {
      if (seenTxHashes.contains(ghostTxn.txhash)) {
        //No-op: Skip those that are already added as swaps/pegs above
        continue;
      }

      final networkTxn =
          networkTxns.firstWhereOrNull((t) => t.txhash == ghostTxn.txhash);

      // If NOT in network yet, check if it should be included (lightning-specific logic)
      if (networkTxn == null) {
        final shouldInclude = _shouldIncludeLightningGhostTransactionAsPending(
          ghostTxn: ghostTxn,
        );
        if (!shouldInclude) {
          continue; // Skip - determined it shouldn't be pending
        }
        // Include as pending
        pendingTxns.add(ghostTxn);
        seenTxHashes.add(ghostTxn.txhash);
        continue;
      }

      // If in network, check if it has enough confirmations
      // networkTxn is guaranteed to be non-null here (we're past the null check)
      final confirmationCount = await confirmationService.getConfirmationCount(
        asset,
        networkTxn.blockHeight ?? 0,
      );
      final confirmationThreshold =
          confirmationService.getRequiredConfirmationCount(asset);

      if (confirmationCount < confirmationThreshold) {
        pendingTxns.add(ghostTxn);
        seenTxHashes.add(ghostTxn.txhash);
      }
    }

    // Boltz transactions are NOT marked as ghost but still need to appear as pending
    final boltzTxns = localDbTxns.where((t) => t.isBoltz).toList();
    final seenBoltzOrderIds = <String>{};

    for (final boltzTxn in boltzTxns) {
      // Use serviceOrderId for deduplication since txhash may be empty for pending Boltz
      final orderId = boltzTxn.serviceOrderId ?? '';
      if (orderId.isNotEmpty && seenBoltzOrderIds.contains(orderId)) {
        continue;
      }

      // Also check txhash if non-empty
      final boltzTxnHash = boltzTxn.txhash;
      if (boltzTxnHash.isNotEmpty && seenTxHashes.contains(boltzTxnHash)) {
        continue;
      }

      // Check if Boltz swap is in a terminal state (expired, refunded, failed, etc.)
      // These should not appear as pending
      if (orderId.isNotEmpty) {
        final order = boltzSwaps.firstWhereOrNull((o) => o.boltzId == orderId);
        final isBoltzSwapTerminal = order?.isTerminal ?? false;

        if (order != null && isBoltzSwapTerminal) {
          continue;
        }
      }

      final networkTxn = boltzTxnHash.isNotEmpty
          ? networkTxns.firstWhereOrNull((t) => t.txhash == boltzTxn.txhash)
          : null;
      final isBroadcastedByAqua = boltzTxnHash.isNotEmpty;
      final isSeenInNetwork = networkTxn != null;

      // If Broadcasted by Aqua but not seen in network , it's still pending
      if (isBroadcastedByAqua && !isSeenInNetwork) {
        pendingTxns.add(boltzTxn);
        if (boltzTxnHash.isNotEmpty) {
          seenTxHashes.add(boltzTxnHash);
        }
        if (orderId.isNotEmpty) {
          seenBoltzOrderIds.add(orderId);
        }
        continue;
      } else if (isSeenInNetwork) {
        // If in network, check if it has enough confirmations
        final confirmationCount =
            await confirmationService.getConfirmationCount(
          asset,
          networkTxn.blockHeight ?? 0,
        );
        final confirmationThreshold =
            confirmationService.getRequiredConfirmationCount(asset);

        if (confirmationCount < confirmationThreshold) {
          pendingTxns.add(boltzTxn);
          if (boltzTxnHash.isNotEmpty) {
            seenTxHashes.add(boltzTxnHash);
          }
          if (orderId.isNotEmpty) {
            seenBoltzOrderIds.add(orderId);
          }
        }
      }
    }

    return pendingTxns;
  }

  List<TransactionUiModel> _buildPendingDbTransactions({
    required Asset asset,
    required List<GdkTransaction> networkTxns,
    required List<Asset> availableAssets,
    required List<TransactionDbModel> pendingTxns,
  }) {
    final uiModels = <TransactionUiModel>[];

    for (final txn in pendingTxns) {
      final networkTxn =
          networkTxns.firstWhereOrNull((nt) => nt.txhash == txn.txhash);
      final strategy = strategyFactory.create(
        dbTransaction: txn,
        networkTransaction: networkTxn,
        asset: asset,
      );

      final args = TransactionStrategyArgs(
        asset: asset,
        availableAssets: availableAssets,
        networkTransaction: networkTxn,
        dbTransaction: txn,
      );

      // Check if transaction should show on this asset page
      if (!strategy.shouldShowTransactionForAsset(args)) {
        continue;
      }

      final uiModel = strategy.createPendingListItems(args);
      if (uiModel != null) {
        final model = uiModel.applyFeeTransactionFlag(
          networkTxn,
          asset,
          availableAssets,
        );
        uiModels.add(model);
      }
    }

    return uiModels;
  }

  // Builds UI models for unconfirmed network transactions
  Future<List<TransactionUiModel>> _buildUnconfirmedNetworkTransactions({
    required Asset asset,
    required List<GdkTransaction> networkTxns,
    required List<TransactionDbModel> localDbTxns,
    required List<Asset> availableAssets,
    required List<TransactionDbModel> pendingTxns,
  }) async {
    final uiModels = <TransactionUiModel>[];
    final pegOrders =
        asset.isSwappable ? await pegStorage.getAllPegOrders() : null;
    final seenServiceOrderIds = <String>{};

    for (final txn in networkTxns) {
      final isAlreadyProcessed = pendingTxns.any((t) => t.txhash == txn.txhash);

      if (isAlreadyProcessed) {
        // No-op: Skip if we already created a UI model for this transaction
        continue;
      }

      TransactionDbModel? dbTxn =
          localDbTxns.firstWhereOrNull((t) => t.txhash == txn.txhash);

      // Check if this transaction matches a peg order
      if (dbTxn == null && pegOrders != null) {
        final pegOrder = pegOrders.findMatchingOrder(
          transactionId: txn.txhash!,
          asset: asset,
          outputs: txn.outputs,
        );
        if (pegOrder != null) {
          dbTxn = TransactionDbModel.fromPegOrderDbModel(
            pegOrder,
            walletId: pegOrder.walletId ?? '',
          );

          // For peg transactions, also check serviceOrderId to prevent duplicates
          // when txhash was empty initially but now has a value
          if (dbTxn.serviceOrderId != null) {
            final isAlreadyProcessedByOrderId = pendingTxns.any(
              (t) => t.isPeg && t.serviceOrderId == dbTxn!.serviceOrderId,
            );
            if (isAlreadyProcessedByOrderId ||
                seenServiceOrderIds.contains(dbTxn.serviceOrderId)) {
              continue;
            }
            seenServiceOrderIds.add(dbTxn.serviceOrderId!);
          }
        }
      }

      final isPending = await confirmationService.isTransactionPending(
        asset: asset,
        transaction: txn,
        dbTransaction: dbTxn,
      );

      if (!isPending) {
        // No-op: Skip if the transaction is not pending
        continue;
      }

      final strategy = strategyFactory.create(
        dbTransaction: dbTxn,
        networkTransaction: txn,
        asset: asset,
      );

      final uiModel = strategy.createPendingListItems(TransactionStrategyArgs(
        asset: asset,
        availableAssets: availableAssets,
        networkTransaction: txn,
        dbTransaction: dbTxn,
      ));
      if (uiModel != null) {
        final model = uiModel.applyFeeTransactionFlag(
          txn,
          asset,
          availableAssets,
        );
        uiModels.add(model);
      }
    }

    return uiModels;
  }

  // Determines if a lightning ghost transaction should be included in the pending list
  // Returns false if the transaction should be skipped (e.g., it's completed but not in network list)
  // Returns true if it should be included as pending
  bool _shouldIncludeLightningGhostTransactionAsPending({
    required TransactionDbModel ghostTxn,
  }) {
    // For lightning ghost transactions not in network list, check Boltz order status
    final orderId = ghostTxn.serviceOrderId;
    if (orderId == null || orderId.isEmpty) {
      return true; // Include if no order ID
    }

    final boltzOrder = boltzSwaps.firstWhereOrNull(
      (o) => o.boltzId == orderId,
    );

    // If Boltz order is terminal AND transaction is older than grace period,
    // it's likely confirmed but beyond the transaction limit
    // Grace period ensures we don't hide recently completed transactions
    if (boltzOrder != null && boltzOrder.isTerminal) {
      final now = DateTime.now();
      final ghostAge = ghostTxn.ghostTxnCreatedAt != null
          ? now.difference(ghostTxn.ghostTxnCreatedAt!)
          : null;
      if (ghostAge != null && ghostAge > _gracePeriod) {
        return false; // Skip - it's completed and old, just not in network list
      }
    }

    return true; // Include as pending
  }
}
