import 'dart:async';

import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart' hide SwapType;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:boltz_dart/boltz_dart.dart';

// ANCHOR - Swap Settlement Provider
final boltzSwapSettlementServiceProvider =
    Provider.autoDispose(BoltzSwapSettlementService.new);

class BoltzSwapSettlementService {
  BoltzSwapSettlementService(this._ref) {
    logger.d('[Boltz] -- BoltzSwapSettlementService init --');
    _initializeMonitoring();
  }

  final AutoDisposeRef _ref;
  final Set<String> _monitoredSwapIds = {};
  final Map<String, bool> _claimsInProgress = {};
  final Map<String, bool> _refundsInProgress = {};
  final Map<String, bool> _coopCloseInProgress = {};

  void _initializeMonitoring() {
    _ref.listen<AsyncValue<List<BoltzSwapDbModel>>>(
      boltzStorageProvider,
      (previous, next) {
        next.whenData((swaps) {
          _monitorSwaps(swaps);
        });
      },
      onError: (error, stackTrace) {
        logger.e('[Boltz] Error in boltzStorageProvider', error, stackTrace);
      },
    );
  }

  Future<void> refreshMonitoring() async {
    _monitoredSwapIds.clear();

    final swaps = await _ref.read(boltzStorageProvider.future);
    logger.d('[Boltz] Refreshing swap monitoring for ${swaps.length} swaps');
    await _monitorSwaps(swaps, forceRefresh: true);
  }

  Future<void> _monitorSwaps(List<BoltzSwapDbModel> swaps,
      {bool forceRefresh = false}) async {
    final submarineSwaps = _getSubmarineSwapsToMonitor(swaps)
        .where(
            (swap) => !_monitoredSwapIds.contains(swap.boltzId) || forceRefresh)
        .toList();
    final reverseSwaps = _getReverseSwapsToMonitor(swaps)
        .where(
            (swap) => !_monitoredSwapIds.contains(swap.boltzId) || forceRefresh)
        .toList();

    logger.d(
        '[Boltz] Refreshing swap monitoring for ${submarineSwaps.length} submarine swaps and ${reverseSwaps.length} reverse swaps');

    for (var swap in [...submarineSwaps, ...reverseSwaps]) {
      await _monitorSingleSwap(swap, forceRefresh: forceRefresh);
    }
  }

  List<BoltzSwapDbModel> _getSubmarineSwapsToMonitor(
      List<BoltzSwapDbModel> swaps) {
    return swaps
        .where((swap) =>
            swap.kind == SwapType.submarine &&
            (swap.lastKnownStatus?.isPending == true ||
                swap.lastKnownStatus?.needsRefund == true) &&
            (swap.refundTxId == null || swap.refundTxId!.isEmpty) &&
            (swap.createdAt == null ||
                (swap.createdAt != null &&
                    DateTime.now().difference(swap.createdAt!).inHours <= 336)))
        .toList();
  }

  List<BoltzSwapDbModel> _getReverseSwapsToMonitor(
      List<BoltzSwapDbModel> swaps) {
    return swaps
        .where((swap) =>
            swap.kind == SwapType.reverse &&
            (swap.lastKnownStatus?.isPending == true ||
                swap.lastKnownStatus?.needsClaim == true) &&
            (swap.claimTxId == null || swap.claimTxId!.isEmpty) &&
            (swap.createdAt == null ||
                (swap.createdAt != null &&
                    DateTime.now().difference(swap.createdAt!).inHours <= 672)))
        .toList();
  }

  Future<void> _monitorSingleSwap(BoltzSwapDbModel swap,
      {bool forceRefresh = false}) async {
    if (!_monitoredSwapIds.contains(swap.boltzId) || forceRefresh) {
      if (forceRefresh) {
        logger.d('[Boltz] Force refresh status sub for ${swap.id}');
        await _ref
            .read(boltzSwapStatusProvider(swap.boltzId).notifier)
            .refreshSubscription();
      }

      _monitoredSwapIds.add(swap.boltzId);
      _ref.listen(boltzSwapStatusProvider(swap.boltzId), (_, next) {
        logger.d('[Boltz] Listening status for ${swap.boltzId}');
        next.whenData((status) async {
          logger.d(
              '[Boltz] Updating status: ${status.status.toString()} for ${swap.boltzId}');
          if (swap.kind == SwapType.submarine) {
            await _handleSubmarineSwapStatus(swap.boltzId, status.status);
          } else if (swap.kind == SwapType.reverse) {
            await _handleReverseSwapStatus(swap.boltzId, status.status);
          }
        });
      }, onError: (error, stackTrace) {
        logger.e('[Boltz] Error monitoring swap: ${swap.boltzId}', error,
            stackTrace);
        _monitoredSwapIds.remove(swap.boltzId);
      });
    }
  }

  Future<void> _handleSubmarineSwapStatus(
      String swapId, BoltzSwapStatus status) async {
    final cachedOrder =
        await _ref.read(boltzStorageProvider.notifier).getSwapById(swapId);

    if (cachedOrder == null) {
      logger.e('[Boltz] Could not find latest swap data for $swapId');
      return;
    }

    if (status == BoltzSwapStatus.transactionClaimPending) {
      if (_coopCloseInProgress[swapId] == true) {
        logger.d(
            '[Boltz] Coop close already in progress for ${cachedOrder.boltzId}. Skipping.');
        return;
      }

      _coopCloseInProgress[swapId] = true;
      try {
        final subSwap = await _ref
            .read(boltzStorageProvider.notifier)
            .getLbtcLnV2SwapById(cachedOrder.boltzId);
        if (subSwap == null) {
          logger.e("[Boltz] Sub swap null, could not post coop close");
          return;
        }
        logger.d("[Boltz] Posting sub swap coop close: ${cachedOrder.boltzId}");
        await subSwap.coopCloseSubmarine();
      } catch (e) {
        logger.e(
            '[Boltz] Error coop closing sub swap: ${cachedOrder.boltzId}', e);
      } finally {
        _coopCloseInProgress[swapId] = false;
      }
      return;
    }

    if (_refundsInProgress[swapId] == true) {
      logger.d(
          '[Boltz] Refund already in progress for ${cachedOrder.boltzId}. Skipping.');
      return;
    }

    if (status.needsRefund) {
      logger.d('[Boltz] Swap needs refund: ${cachedOrder.boltzId}');
      _refundsInProgress[swapId] = true;
      try {
        final boltzSwap = await _ref
            .read(boltzStorageProvider.notifier)
            .getLbtcLnV2SwapById(cachedOrder.boltzId);
        if (boltzSwap == null) return;
        final tx = await refund(boltzSwap);

        if (tx != null) {
          await _closeSwap(cachedOrder.boltzId);
        }
      } finally {
        _refundsInProgress[swapId] = false;
      }
    }
  }

  Future<void> _handleReverseSwapStatus(
      String swapId, BoltzSwapStatus status) async {
    final cachedOrder =
        await _ref.read(boltzStorageProvider.notifier).getSwapById(swapId);
    logger.d(
        '[Boltz] Refreshing claim order, has claim tx: ${cachedOrder?.claimTxId}');

    if (cachedOrder == null) {
      logger.e('[Boltz] Could not find latest swap data for $swapId');
      return;
    }

    if (cachedOrder.claimTxId != null && cachedOrder.claimTxId!.isNotEmpty) {
      logger.d(
          '[Boltz] Swap ${cachedOrder.boltzId} has already been claimed. Skipping.');
      await _closeSwap(cachedOrder.boltzId);
      return;
    }

    if (_claimsInProgress[swapId] == true) {
      logger.d(
          '[Boltz] Claim already in progress for ${cachedOrder.boltzId}. Skipping.');
      return;
    }

    if (status.needsClaim &&
        (cachedOrder.claimTxId == null || cachedOrder.claimTxId!.isEmpty)) {
      logger.d('[Boltz] Swap needs claim: ${cachedOrder.boltzId}');
      _claimsInProgress[swapId] = true;
      try {
        final boltzSwap = await _ref
            .read(boltzStorageProvider.notifier)
            .getLbtcLnV2SwapById(cachedOrder.boltzId);
        if (boltzSwap == null) return;
        final tx = await claim(boltzSwap);

        if (tx != null) {
          await _closeSwap(cachedOrder.boltzId);
        }
      } finally {
        _claimsInProgress[swapId] = false;
      }
    }
  }

  Future<void> _closeSwap(String boltzId) async {
    try {
      _monitoredSwapIds.remove(boltzId);
      _claimsInProgress.remove(boltzId);
      _refundsInProgress.remove(boltzId);
      _coopCloseInProgress.remove(boltzId);
      _ref.invalidate(boltzSwapStatusProvider(boltzId));
      _ref.read(boltzWebSocketProvider).unsubscribe(boltzId);
      logger.d('[Boltz] Closed swap: $boltzId');
    } catch (e) {
      logger.e('[Boltz] Error closing swap: $boltzId', e);
    }
  }

  Future<String?> refund(LbtcLnSwap swap, {bool tryCoop = true}) async {
    logger.d('[Boltz] Refunding Boltz Swap: ${swap.id}');

    try {
      final address = await _ref.read(liquidProvider).getReceiveAddress();
      if (address == null || address.address == null) {
        throw Exception(
            'Receive address is null when trying to construct refund tx');
      }

      final fees = await Fees.newInstance(boltzUrl: boltzV2MainnetUrl);
      final subFees = await fees.submarine();
      final refundBytes = await swap.refund(
        outAddress: address.address!,
        absFee: subFees.lbtcFees.minerFees,
        tryCooperate: tryCoop,
      );

      logger.d('[Boltz] Boltz Swap Refund tx bytes: $refundBytes');

      final broadcastResponse =
          await broadcast(swap, refundBytes, isLowball: true);

      await _ref
          .read(boltzStorageProvider.notifier)
          .updateRefundTxId(boltzId: swap.id, txId: broadcastResponse);

      logger.d('[Boltz] Boltz Swap Refund response: $broadcastResponse');
      return broadcastResponse;
    } catch (e) {
      // if coop/keypath refund fails, try the scriptpath (will only happen if boltz is down or uncooperative)
      if (tryCoop) {
        return await refund(swap, tryCoop: false);
      }
      logger.e('[Boltz] Error refunding Boltz Swap: ${swap.id}', e);
      rethrow;
    }
  }

  // There are currently two failure paths for claims (and refunds)
  // 1. The musig coop claim fails (should only happen if boltz goes offline)
  // 2. Lowball send fails
  //
  // Both of these should be rare, and #2 should be removed with Cheap CT
  Future<String?> claim(LbtcLnSwap swap,
      {bool tryCoop = true, bool tryLowball = true}) async {
    logger.d('[Boltz] Claiming Boltz Swap: ${swap.id}');
    try {
      final address = await _ref.read(liquidProvider).getReceiveAddress();
      if (address == null || address.address == null) {
        throw Exception(
            'Receive address is null when trying to construct claim tx');
      }

      final fees = await Fees.newInstance(boltzUrl: boltzV2MainnetUrl);
      final reverseFees = await fees.reverse();

      final fee = _calculateClaimFee(tryLowball, tryCoop, reverseFees);

      final claimBytes = await swap.claim(
        outAddress: address.address!,
        absFee: fee,
        tryCooperate: tryCoop,
      );
      logger.d('[Boltz] Boltz Swap Claim bytes: $claimBytes');

      final broadcastResponse =
          await broadcast(swap, claimBytes, isLowball: tryLowball);

      logger.d('[Boltz] Boltz Swap Claim response: $broadcastResponse');

      // Update local cache
      await _ref.read(boltzStorageProvider.notifier).updateReverseSwapClaim(
            boltzId: swap.id,
            claimTxId: broadcastResponse,
            receiveAddress: address.address!,
            outAmount: swap.outAmount,
            fee: reverseFees.lbtcFees.minerFees.claim,
          );

      return broadcastResponse;
    } catch (e) {
      // 1. if coop/keypath claim fails, try the scriptpath (will only happen if boltz is down or uncooperative)
      // 2. if that fails, try non-lowball
      if (tryCoop) {
        logger.e('[Boltz] Error claiming coop ${swap.id} - trying non-coop', e);
        return await claim(swap, tryCoop: false);
      } else if (!tryCoop && tryLowball) {
        logger.e(
            '[Boltz] Error claiming lowball ${swap.id} - trying non-lowball',
            e);
        return await claim(swap, tryCoop: true, tryLowball: false);
      }
      logger.e('[Boltz] Error claiming Boltz Swap: ${swap.id}', e);
      rethrow;
    }
  }

  // TODO: There is an issue on boltz-rust to allow passing a fee rate. When implement we can greatly simply with just the single condition of lowball or no-lowball fee rate
  // - https://github.com/SatoshiPortal/boltz-rust/issues/56
  int _calculateClaimFee(
      bool tryLowball, bool tryCoop, ReverseFeesAndLimits reverseFees) {
    if (tryLowball && tryCoop) {
      return reverseFees.lbtcFees.minerFees.claim;
    } else if (tryLowball && !tryCoop) {
      return kBoltzLiquidClaimTxFeeLowball_NonCoop;
    } else if (!tryLowball && tryCoop) {
      return kBoltzLiquidClaimTxFee;
    } else {
      // This case should not occur (!tryLowball && !tryCoop)
      return kBoltzLiquidClaimTxFee;
    }
  }

  Future<String> broadcast(LbtcLnSwap swap, String tx,
      {required bool isLowball}) async {
    if (isLowball) {
      return await _broadcastWithAqua(tx);
    }

    return await _broadcastWithBoltz(swap, tx);
  }

  Future<String> _broadcastWithAqua(String tx) async {
    try {
      return await _ref
          .read(electrsProvider)
          .broadcast(tx, NetworkType.liquid, isLowball: true);
    } catch (e) {
      logger.e('[Boltz] Error broadcasting with Aqua (lowball): $e');
      rethrow;
    }
  }

  Future<String> _broadcastWithBoltz(LbtcLnSwap swap, String tx) async {
    try {
      final txId = await swap.broadcastBoltz(signedHex: tx);
      logger.d(
          '[Boltz] Successfully broadcasted transaction with Boltz. TxID: $txId');
      return txId;
    } catch (e) {
      logger.e('[Boltz] Error broadcasting with Boltz: $e');
      rethrow;
    }
  }
}
