import 'dart:async';

import 'package:aqua/data/models/database/peg_order_model.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/logger.dart';

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
      final consolidatedCachedStatus = _getConsolidatedStatus(cachedStatus);
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
      final consolidatedStatus = _getConsolidatedStatus(response.result!);
      state = PegStatusState(
        fullStatus: response.result,
        consolidatedStatus: consolidatedStatus,
      );
      await _updateCachedStatus(response.result!);
    }
  }

  /// TODO: This is a temporary solution to provide a single overall state.
  /// The long-term fix involves showing a list of all deposit
  /// txs with their individual statuses.
  /// Multiple txs would be an edge cases anyway. Aqua controlled pegs will ohly send one tx per order.
  /// Multiple txs would only come from External Peg-in/out
  ///
  /// Priority order: Done > Processing > Detected > InsufficientAmount
  ConsolidatedPegStatus _getConsolidatedStatus(SwapPegStatusResult status) {
    if (status.transactions.isEmpty) {
      logger.debug('[Sideswap][PegStatus] Transactions are empty');
      return const ConsolidatedPegStatus(state: null);
    }

    logger.debug(
        '[Sideswap][PegStatus] Number of transactions: ${status.transactions.length}');
    final doneTxn = status.transactions
        .firstWhereOrNull((tx) => tx.txState == PegTxState.done);
    final processingTxn = status.transactions
        .firstWhereOrNull((tx) => tx.txState == PegTxState.processing);
    final detectedTxn = status.transactions
        .firstWhereOrNull((tx) => tx.txState == PegTxState.detected);
    final insufficientAmountTxn = status.transactions
        .firstWhereOrNull((tx) => tx.txState == PegTxState.insufficientAmount);

    if (doneTxn != null) {
      logger.debug('[Sideswap][PegStatus] Found done transaction');
      return ConsolidatedPegStatus(
          state: PegTxState.done, transaction: doneTxn);
    }
    if (processingTxn != null) {
      logger.debug(
          '[Sideswap][PegStatus] Found processing transaction. Confs: ${processingTxn.detectedConfs}/${processingTxn.totalConfs}');
      return ConsolidatedPegStatus(
        state: PegTxState.processing,
        transaction: processingTxn,
        detectedConfs: processingTxn.detectedConfs,
        totalConfs: processingTxn.totalConfs,
      );
    }
    if (detectedTxn != null) {
      logger.debug('[Sideswap][PegStatus] Found detected transaction');
      return ConsolidatedPegStatus(
          state: PegTxState.detected, transaction: detectedTxn);
    }
    if (insufficientAmountTxn != null) {
      logger
          .debug('[Sideswap][PegStatus] Found insufficient amount transaction');
      return ConsolidatedPegStatus(
          state: PegTxState.insufficientAmount,
          transaction: insufficientAmountTxn);
    }

    logger.debug('[Sideswap][PegStatus] No relevant transaction found');
    return const ConsolidatedPegStatus(state: null);
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
    final consolidatedStatus = _getConsolidatedStatus(result);
    return 'state: ${consolidatedStatus.state}, '
        'detectedConfs: ${consolidatedStatus.detectedConfs}, '
        'totalConfs: ${consolidatedStatus.totalConfs}';
  }
}
