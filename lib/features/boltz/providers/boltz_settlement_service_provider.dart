import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/providers/transactions_storage_provider.dart';
import 'package:aqua/logger.dart';
import 'package:boltz/boltz.dart';

final _logger = CustomLogger(FeatureFlag.boltz);

// ANCHOR - Swap Settlement Provider
final boltzSwapSettlementServiceProvider =
    Provider.autoDispose(BoltzSwapSettlementService.new);

class BoltzSwapSettlementService {
  BoltzSwapSettlementService(this._ref) {
    _logger.debug('[Boltz] -- BoltzSwapSettlementService init --');
    _initialize();
  }

  Future<void> _initialize() async {
    _initializeMonitoring();

    // Force an initial monitoring of current swaps
    final swaps = await _ref.read(boltzStorageProvider.future);
    await _monitorSwaps(swaps, forceRefresh: true);
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
        _logger.error('Error in boltzStorageProvider', error, stackTrace);
      },
    );
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

    if (submarineSwaps.isNotEmpty || reverseSwaps.isNotEmpty) {
      _logger.info(
          '[Boltz] Refreshing swap monitoring for ${submarineSwaps.length} submarine swaps and ${reverseSwaps.length} reverse swaps');
    }

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
        .toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
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
        .toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }

  Future<void> _monitorSingleSwap(BoltzSwapDbModel swap,
      {bool forceRefresh = false}) async {
    if (!_monitoredSwapIds.contains(swap.boltzId) || forceRefresh) {
      if (forceRefresh) {
        _logger.info('[Boltz] Force refresh status sub for ${swap.id}');
        _ref.invalidate(boltzSwapStatusProvider(swap.boltzId));
      }

      _monitoredSwapIds.add(swap.boltzId);
      _logger.info('Adding single swap to monitor: ${swap.boltzId}');

      _ref.listen(boltzSwapStatusProvider(swap.boltzId), (_, next) {
        _logger.debug('[Boltz] Listening status for ${swap.boltzId}');
        next.whenData((status) async {
          _logger.info(
              '[Boltz] Updating status: ${status.status.toString()} for ${swap.boltzId}');
          if (swap.kind == SwapType.submarine) {
            await _handleSubmarineSwapStatus(swap.boltzId, status.status);
          } else if (swap.kind == SwapType.reverse) {
            await _handleReverseSwapStatus(swap.boltzId, status.status);
          }
        });
      }, onError: (error, stackTrace) {
        _logger.error(
            'Error monitoring swap: ${swap.boltzId}', error, stackTrace);
        _monitoredSwapIds.remove(swap.boltzId);
      });
    }
  }

  Future<void> _handleSubmarineSwapStatus(
      String swapId, BoltzSwapStatus status) async {
    final cachedOrder =
        await _ref.read(boltzStorageProvider.notifier).getSwapById(swapId);

    if (cachedOrder == null) {
      _logger.error('[Boltz] Could not find latest swap data for $swapId');
      return;
    }

    await _ref
        .read(boltzStorageProvider.notifier)
        .updateBoltzSwapStatus(boltzId: swapId, status: status);

    if (status == BoltzSwapStatus.transactionClaimPending) {
      if (_coopCloseInProgress[swapId] == true) {
        _logger.debug(
            '[Boltz] Coop close already in progress for ${cachedOrder.boltzId}. Skipping.');
        return;
      }

      final tryCoop = await _shouldTryCoopSubmarineSwap(cachedOrder);
      if (!tryCoop) {
        _logger.debug(
            '[Boltz] Skipping normal swap coop close for batched amount: ${cachedOrder.boltzId}');
        return;
      }

      _coopCloseInProgress[swapId] = true;

      try {
        final subSwap = await _ref
            .read(boltzStorageProvider.notifier)
            .getLbtcLnV2SwapById(cachedOrder.boltzId);
        if (subSwap == null) {
          _logger.error("[Boltz] Sub swap null, could not post coop close");
          return;
        }
        _logger.debug(
            "[Boltz] Posting sub swap coop close: ${cachedOrder.boltzId}");
        await subSwap.coopCloseSubmarine();
      } catch (e) {
        _logger.error(
            '[Boltz] Error coop closing sub swap: ${cachedOrder.boltzId}', e);
      } finally {
        _coopCloseInProgress[swapId] = false;
      }
      return;
    }

    if (_refundsInProgress[swapId] == true) {
      _logger.debug(
          '[Boltz] Refund already in progress for ${cachedOrder.boltzId}. Skipping.');
      return;
    }

    if (status.needsRefund) {
      _logger.debug('[Boltz] Swap needs refund: ${cachedOrder.boltzId}');
      _refundsInProgress[swapId] = true;
      try {
        final boltzSwap = await _ref
            .read(boltzStorageProvider.notifier)
            .getLbtcLnV2SwapById(cachedOrder.boltzId);
        if (boltzSwap == null) return;
        final tryCoop = await _shouldTryCoopSubmarineSwap(cachedOrder);
        final tx = await refund(boltzSwap, tryCoop: tryCoop);

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

    if (cachedOrder == null) {
      logger.error('[Boltz] Could not find latest swap data for $swapId');
      return;
    }

    await _ref
        .read(boltzStorageProvider.notifier)
        .updateBoltzSwapStatus(boltzId: swapId, status: status);

    if (cachedOrder.claimTxId != null && cachedOrder.claimTxId!.isNotEmpty) {
      _logger.debug(
          '[Boltz] Swap ${cachedOrder.boltzId} has already been claimed. Skipping.');
      await _closeSwap(cachedOrder.boltzId);
      return;
    }

    if (_claimsInProgress[swapId] == true) {
      _logger.debug(
          '[Boltz] Claim already in progress for ${cachedOrder.boltzId}. Skipping.');
      return;
    }

    if (status.needsClaim &&
        (cachedOrder.claimTxId == null || cachedOrder.claimTxId!.isEmpty)) {
      _logger.debug('[Boltz] Swap needs claim: ${cachedOrder.boltzId}');
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
      final swap =
          await _ref.read(boltzStorageProvider.notifier).getSwapById(boltzId);
      if (swap != null) {
        final apiUrl = swap.boltzUrl?.isNotEmpty == true
            ? swap.boltzUrl!
            : await _ref.read(boltzApiUrlProvider(swap.kind).future);
        await _ref.read(boltzWebSocketProvider(apiUrl)).unsubscribe(boltzId);
      }
      _logger.debug('[Boltz] Closed swap: $boltzId');
    } catch (e) {
      _logger.error('Error closing swap: $boltzId', e);
    }
  }

  Future<bool> _shouldTryCoopSubmarineSwap(BoltzSwapDbModel swap) async {
    try {
      final fees =
          await _ref.read(boltzFeesProvider(SwapType.submarine).future);
      final limits = (await fees.submarine()).lbtcLimits;
      final amount = swap.amountFromInvoice ?? swap.outAmount;
      return BoltzFees.shouldTryCoopSubmarineSwap(
        amountSats: amount,
        limits: limits,
      );
    } catch (e, stackTrace) {
      _logger.error(
          '[Boltz] Failed to fetch normal swap limits, defaulting to coop',
          e,
          stackTrace);
      return true;
    }
  }

  Future<String?> refund(LbtcLnSwap swap, {bool tryCoop = true}) async {
    _logger.debug('Refunding Boltz Swap: ${swap.id}');

    try {
      final address = await _ref.read(liquidProvider).getReceiveAddress();
      if (address == null || address.address == null) {
        throw Exception(
            'Receive address is null when trying to construct refund tx');
      }

      final refundBytes = await swap.refund(
        outAddress: address.address!,
        minerFee: TxFee.absolute(BigInt.from(kBoltzLiquidRefundTxFee)),
        tryCooperate: tryCoop,
      );

      _logger.debug('Boltz Swap Refund tx bytes: $refundBytes');

      final broadcastResponse = await broadcast(swap, refundBytes);

      await _ref
          .read(boltzStorageProvider.notifier)
          .updateRefundTxId(boltzId: swap.id, txId: broadcastResponse);

      await _ref
          .read(transactionStorageProvider.notifier)
          .saveBoltzRefundTxn(boltzSwap: swap, txId: broadcastResponse);

      _logger.debug('Boltz Swap Refund response: $broadcastResponse');
      return broadcastResponse;
    } catch (e) {
      // if coop/keypath refund fails, try the scriptpath (will only happen if boltz is down or uncooperative)
      if (tryCoop) {
        return await refund(swap, tryCoop: false);
      }
      _logger.error('Error refunding Boltz Swap: ${swap.id}', e);
      rethrow;
    }
  }

  // NOTE: The musig coop claim can fail (should only happen if boltz goes offline)
  Future<String?> claim(LbtcLnSwap swap, {bool tryCoop = true}) async {
    _logger.debug('[Boltz] Claiming Boltz Swap: ${swap.id}');

    late final String broadcastResponse;
    late final String receiveAddress;
    late final int fee;

    try {
      final address = await _ref.read(liquidProvider).getReceiveAddress();
      if (address == null || address.address == null) {
        throw Exception(
            'Receive address is null when trying to construct claim tx');
      }
      receiveAddress = address.address!;
      fee = _calculateClaimFee(tryCoop);

      final claimBytes = await swap.claim(
        outAddress: receiveAddress,
        minerFee: TxFee.absolute(BigInt.from(fee)),
        tryCooperate: tryCoop,
      );

      _logger.debug('Boltz Swap Claim bytes: $claimBytes');

      broadcastResponse = await broadcast(swap, claimBytes);
      _logger.debug('[Boltz] Boltz Swap Claim response: $broadcastResponse');
    } catch (e) {
      if (tryCoop) {
        _logger.error(
            '[Boltz] Error claiming coop ${swap.id} - trying non-coop ${e.toString()}');
        return await claim(swap, tryCoop: false);
      }

      _logger.error('Error claiming Boltz Swap: ${swap.id} - ${e.toString()}');
      rethrow;
    }

    // DB updates are outside the broadcast retry scope so a coop failure
    // cannot trigger a non-coop retry that overwrites the stored txhash.
    // Wrapped in its own try/catch so a DB error doesn't lose the txhash
    // that was already broadcast on-chain.
    try {
      await _ref.read(boltzStorageProvider.notifier).updateReverseSwapClaim(
            boltzId: swap.id,
            claimTxId: broadcastResponse,
            receiveAddress: receiveAddress,
            outAmount: swap.outAmount.toInt(),
            fee: fee,
          );
    } catch (e) {
      _logger.error('[Boltz] DB save failed after successful claim broadcast '
          '(txId: $broadcastResponse, swapId: ${swap.id}): $e');
    }

    return broadcastResponse;
  }

  Future<String?> claimBySwapId(String swapId) async {
    if (_claimsInProgress[swapId] == true) {
      _logger.debug('[Boltz] Claim already in progress for $swapId. Skipping.');
      return null;
    }

    _claimsInProgress[swapId] = true;
    try {
      final swap = await _ref
          .read(boltzStorageProvider.notifier)
          .getLbtcLnV2SwapById(swapId);
      if (swap != null) {
        return await claim(swap);
      }
      return null;
    } finally {
      _claimsInProgress[swapId] = false;
    }
  }

  Future<String?> refundBySwapId(String swapId) async {
    final cachedOrder =
        await _ref.read(boltzStorageProvider.notifier).getSwapById(swapId);
    final swap = await _ref
        .read(boltzStorageProvider.notifier)
        .getLbtcLnV2SwapById(swapId);
    if (swap == null) return null;

    final tryCoop = cachedOrder?.kind == SwapType.submarine
        ? await _shouldTryCoopSubmarineSwap(cachedOrder!)
        : true;
    return refund(swap, tryCoop: tryCoop);
  }

  // TODO: There is an issue on boltz-rust to allow passing a fee rate. When implement we can greatly simply with just the single condition of lowball or no-lowball fee rate
  // - https://github.com/SatoshiPortal/boltz-rust/issues/56
  int _calculateClaimFee(bool tryCoop) {
    if (tryCoop) {
      return kBoltzLiquidClaimTxFee;
    } else {
      return kBoltzLiquidClaimTxFee_NonCoop;
    }
  }

  Future<String> broadcast(LbtcLnSwap swap, String tx) async {
    return await _ref.read(electrsProvider).broadcast(tx, NetworkType.liquid);
  }
}
