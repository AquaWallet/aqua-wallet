import 'dart:async';

import 'package:coin_cz/data/models/database/peg_order_model.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/logger.dart';

const kStatusCheckInterval = Duration(seconds: 15);

typedef SwapStatusParams = ({
  String orderId,
  bool isPegIn,
});

final pegStatusProvider =
    NotifierProvider.autoDispose<_Notifier, PegStatusState>(_Notifier.new);

class _Notifier extends AutoDisposeNotifier<PegStatusState> {
  SwapStatusParams? params;

  @override
  PegStatusState build() {
    Timer.periodic(kStatusCheckInterval, (_) {
      if (params != null) {
        requestPegStatus(
          orderId: params!.orderId,
          isPegIn: params!.isPegIn,
        );
      }
    });
    return const PegStatusState();
  }

  Future<void> requestPegStatus({
    required String orderId,
    required bool isPegIn,
  }) async {
    params = (orderId: orderId, isPegIn: isPegIn);

    final cachedStatus = await _getCachedStatus(orderId);
    if (cachedStatus != null) {
      final consolidatedCachedStatus = cachedStatus.getConsolidatedStatus();
      if (consolidatedCachedStatus.state == PegTxState.done) {
        logger.debug('[Sideswap][PegStatus] Found done status in local cache');
        state = PegStatusState(
          fullStatus: cachedStatus,
          consolidatedStatus: consolidatedCachedStatus,
        );
        return;
      }
    }

    ref
        .read(sideswapWebsocketProvider)
        .requestPegStatus(orderId: orderId, isPegIn: isPegIn);
  }

  void processPegStatus(SwapPegStatusResponse response) async {
    logger.debug('[Sideswap][PegStatus] Status: ${response.result}');
    if (response.result != null) {
      final consolidatedStatus = response.result!.getConsolidatedStatus();
      state = PegStatusState(
        fullStatus: response.result,
        consolidatedStatus: consolidatedStatus,
      );
      await _updateCachedStatus(response.result!);
    }
  }

  Future<SwapPegStatusResult?> _getCachedStatus(String orderId) async {
    final cachedOrder =
        await ref.read(pegStorageProvider.notifier).getOrderById(orderId);
    return cachedOrder?.status;
  }

  Future<void> _updateCachedStatus(SwapPegStatusResult result) async {
    final orderId = result.orderId;
    if (orderId != null) {
      final existingOrder =
          await ref.read(pegStorageProvider.notifier).getOrderById(orderId);
      if (existingOrder != null) {
        final updatedOrder = existingOrder.copyWithStatus(result);
        await ref.read(pegStorageProvider.notifier).save(updatedOrder);
        logger.debug(
            '[Sideswap][PegStatus] Updated cached status for order: $orderId, status: ${_getStatusString(result)}');
      } else {
        final newOrder = PegOrderDbModel.fromStatus(
          orderId: orderId,
          isPegIn: result.pegIn ?? false,
          amount: result.transactions.firstOrNull?.amount ?? 0,
          status: result,
          createdAt: DateTime.fromMillisecondsSinceEpoch(result.createdAt ?? 0),
        );
        await ref.read(pegStorageProvider.notifier).save(newOrder);
        logger.debug(
            '[Sideswap][PegStatus] Created new cached status for order: $orderId, status: ${_getStatusString(result)}');
      }
    } else {
      logger.error(
          '[Sideswap][PegStatus] Cannot update cached status: orderId is null');
    }
  }

  String _getStatusString(SwapPegStatusResult result) {
    final consolidatedStatus = result.getConsolidatedStatus();
    return 'state: ${consolidatedStatus.state}, '
        'detectedConfs: ${consolidatedStatus.detectedConfs}, '
        'totalConfs: ${consolidatedStatus.totalConfs}';
  }
}
