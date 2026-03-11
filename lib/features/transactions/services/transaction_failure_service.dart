import 'package:aqua/data/data.dart';
import 'package:aqua/features/sideswap/models/peg_status_state.dart';
import 'package:aqua/features/sideswap/models/sideswap.dart' show PegTxState;
import 'package:aqua/features/sideswap/providers/peg_storage_provider.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';
import 'package:aqua/features/swaps/providers/swap_db_order_provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides consolidated failure evaluation across different transaction types.

final txnFailureServiceProvider =
    Provider.autoDispose<TxnFailureService>(TxnFailureService.new);

class TxnFailureService {
  const TxnFailureService(this._ref);

  final Ref _ref;

  bool isFailed(TransactionDbModel? dbTx) {
    if (dbTx == null) return false;

    // Boltz lightning send
    if (dbTx.isBoltzSendFailed) return true;

    // USDt SideShift swap
    final orderId = dbTx.serviceOrderId;
    if (dbTx.isUSDtSwap && orderId != null) {
      final order = _ref.read(swapDBOrderProvider(orderId)).asData?.value;
      if (order != null) {
        return switch (order.status) {
          SwapOrderStatus.failed ||
          SwapOrderStatus.refunding ||
          SwapOrderStatus.refunded ||
          SwapOrderStatus.expired =>
            true,
          _ => false,
        };
      }
    }

    // SideSwap peg
    if (dbTx.isPeg && dbTx.serviceOrderId != null) {
      final pegOrders = _ref.read(pegStorageProvider).asData?.value ?? [];
      final pegOrder = pegOrders
          .firstWhereOrNull((order) => order.orderId == dbTx.serviceOrderId);

      if (pegOrder != null) {
        final consolidatedState = pegOrder.status.getConsolidatedStatus().state;
        if (consolidatedState == PegTxState.insufficientAmount) {
          return true;
        }
      }
    }

    // TODO: Add failure detection for future/missing services

    return false;
  }
}
