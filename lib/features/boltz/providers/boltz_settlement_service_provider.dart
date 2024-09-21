import 'dart:async';

import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart' hide SwapType;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/providers/transactions_storage_provider.dart';
import 'package:aqua/logger.dart';
import 'package:boltz_dart/boltz_dart.dart';

// ANCHOR - Swap Settlement Provider
final boltzSwapSettlementServiceProvider =
    Provider.autoDispose(BoltzSwapSettlementService.new);

class BoltzSwapSettlementService {
  BoltzSwapSettlementService(this._ref) {
    _monitorExistingSwaps();
    _listenForNewSwaps();
  }

  final AutoDisposeRef _ref;
  final Set<String> _monitoredSwapIds = {};

  void _listenForNewSwaps() {
    _ref.listen<AsyncValue<List<BoltzSwapDbModel>>>(
      boltzStorageProvider,
      (_, __) {},
      onError: (error, stackTrace) {
        logger.e('[Boltz] Error in boltzStorageProvider', error, stackTrace);
      },
    );

    _ref.read(boltzStorageProvider.notifier).newSwapStream.listen((newSwap) {
      _monitorSingleSwap(newSwap);
    });
  }

  Future<void> _monitorExistingSwaps() async {
    final submarineSwaps = await _getSubmarineSwapsToMonitor();
    final reverseSwaps = await _getReverseSwapsToMonitor();

    logger.d('[Boltz] Monitoring submarine swaps: ${submarineSwaps.length}');
    logger.d('[Boltz] Monitoring reverse swaps: ${reverseSwaps.length}');

    for (var swap in [...submarineSwaps, ...reverseSwaps]) {
      _monitorSingleSwap(swap);
    }
  }

  void _monitorSingleSwap(BoltzSwapDbModel swap) {
    if (!_monitoredSwapIds.contains(swap.boltzId)) {
      _monitoredSwapIds.add(swap.boltzId);
      logger.d('[Boltz] Adding single swap to monitor: ${swap.boltzId}');
      _ref.listen(boltzSwapStatusProvider(swap.boltzId), (_, next) {
        next.whenData((status) async {
          if (swap.kind == SwapType.submarine) {
            await _handleSubmarineSwapStatus(swap, status.status);
          } else if (swap.kind == SwapType.reverse) {
            await _handleReverseSwapStatus(swap, status.status);
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
      BoltzSwapDbModel swap, BoltzSwapStatus status) async {
    if (status == BoltzSwapStatus.transactionClaimPending) {
      final subSwap = await _ref
          .read(boltzStorageProvider.notifier)
          .getLbtcLnV2SwapById(swap.boltzId);
      if (subSwap == null) {
        logger.e("[Boltz] Sub swap null, could not post coop close");
        return;
      }
      logger.d("[Boltz] Posting sub swap coop close");
      await subSwap.coopCloseSubmarine();
      return;
    }

    if (status.needsRefund) {
      logger.d('[Boltz] Swap needs refund: ${swap.boltzId}');
      final boltzSwap = await _ref
          .read(boltzStorageProvider.notifier)
          .getLbtcLnV2SwapById(swap.boltzId);
      if (boltzSwap == null) return;
      final tx = await refund(boltzSwap);

      if (tx != null) {
        await _closeSwap(swap.boltzId);
      }
    }
  }

  Future<void> _handleReverseSwapStatus(
      BoltzSwapDbModel swap, BoltzSwapStatus status) async {
    if (status.needsClaim &&
        (swap.claimTxId == null || swap.claimTxId!.isEmpty)) {
      logger.d('[Boltz] Swap needs claim: ${swap.boltzId}');
      final boltzSwap = await _ref
          .read(boltzStorageProvider.notifier)
          .getLbtcLnV2SwapById(swap.boltzId);
      if (boltzSwap == null) return;
      final tx = await claim(boltzSwap);

      if (tx != null) {
        await _closeSwap(swap.boltzId);
      }
    }
  }

  Future<List<BoltzSwapDbModel>> _getSubmarineSwapsToMonitor() async {
    return await _ref.read(boltzStorageProvider.future).then((swaps) {
      return swaps
          .where((swap) =>
              swap.kind == SwapType.submarine &&
              (swap.lastKnownStatus?.isPending == true ||
                  swap.lastKnownStatus?.needsRefund == true) &&
              (swap.refundTxId == null || swap.refundTxId!.isEmpty) &&
              (swap.createdAt == null ||
                  (swap.createdAt != null &&
                      DateTime.now().difference(swap.createdAt!).inHours <=
                          336))) // max 2 weeks so we don't constantly try to refund old swaps. users can manually refund after this period.
          .toList();
    });
  }

  Future<List<BoltzSwapDbModel>> _getReverseSwapsToMonitor() async {
    return await _ref.read(boltzStorageProvider.future).then((swaps) {
      return swaps
          .where((swap) =>
              swap.kind == SwapType.reverse &&
              (swap.lastKnownStatus?.isPending == true ||
                  swap.lastKnownStatus?.needsClaim == true) &&
              (swap.claimTxId == null || swap.claimTxId!.isEmpty) &&
              (swap.createdAt == null ||
                  (swap.createdAt != null &&
                      DateTime.now().difference(swap.createdAt!).inHours <=
                          672))) // bump to a month temporarily to allow claims for taproot claim bug in 0.2.0
          .toList();
    });
  }

  Future<void> _closeSwap(String boltzId) async {
    try {
      _monitoredSwapIds.remove(boltzId);
      _ref.read(boltzSwapStatusProvider(boltzId).notifier).closeStream();
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

      final broadcastResponse = await broadcast(refundBytes);

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

  Future<String?> claim(LbtcLnSwap swap, {bool tryCoop = true}) async {
    logger.d('[Boltz] Claiming Boltz Swap: ${swap.id}');
    try {
      final address = await _ref.read(liquidProvider).getReceiveAddress();
      if (address == null || address.address == null) {
        throw Exception(
            'Receive address is null when trying to construct claim tx');
      }

      final fees = await Fees.newInstance(boltzUrl: boltzV2MainnetUrl);
      final reverseFees = await fees.reverse();
      final claimBytes = await swap.claim(
        outAddress: address.address!,
        absFee: reverseFees.lbtcFees.minerFees.claim,
        tryCooperate: tryCoop,
      );
      logger.d('[Boltz] Boltz Swap Claim bytes: $claimBytes');

      final broadcastResponse = await broadcast(claimBytes);

      logger.d('[Boltz] Boltz Swap Claim response: $broadcastResponse');

      // update boltz cache
      await _ref
          .read(boltzStorageProvider.notifier)
          .updateClaimTxId(boltzId: swap.id, txId: broadcastResponse);

      // update main tx cache
      await _ref
          .read(transactionStorageProvider.notifier)
          .updateReceiveAddressForBoltzId(
              boltzId: swap.id, newReceiveAddress: address.address!);

      await _ref.read(transactionStorageProvider.notifier).markBoltzGhostTxn(
          swap.id,
          amount: swap.outAmount,
          fee: reverseFees.lbtcFees.minerFees.claim);

      return broadcastResponse;
    } catch (e) {
      // if coop/keypath claim fails, try the scriptpath (will only happen if boltz is down or uncooperative)
      if (tryCoop) {
        return await claim(swap, tryCoop: false);
      }
      logger.e('[Boltz] Error claiming Boltz Swap: ${swap.id}', e);
      rethrow;
    }
  }

  Future<String> broadcast(String tx) async {
    try {
      return await _ref
          .read(electrsProvider)
          .broadcast(tx, NetworkType.liquid, isLowball: true);
    } on AquaTxBroadcastException {
      logger.e('[Boltz] Aqua broadcast error, retrying with Blockstream...');
      return await _ref
          .read(electrsProvider)
          .broadcast(tx, NetworkType.liquid, isLowball: false);
    }
  }
}
