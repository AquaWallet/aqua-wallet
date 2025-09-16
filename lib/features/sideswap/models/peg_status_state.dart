import 'package:coin_cz/features/shared/shared.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:coin_cz/features/sideswap/models/sideswap.dart';
import 'package:coin_cz/logger.dart';

part 'peg_status_state.freezed.dart';
part 'peg_status_state.g.dart';

final _logger = CustomLogger(FeatureFlag.sideswap);

@freezed
class PegStatusState with _$PegStatusState {
  const factory PegStatusState({
    SwapPegStatusResult? fullStatus,
    ConsolidatedPegStatus? consolidatedStatus,
  }) = _PegStatusState;

  factory PegStatusState.fromJson(Map<String, dynamic> json) =>
      _$PegStatusStateFromJson(json);
}

extension PegStatusStateX on PegStatusState {
  bool get isPending {
    final state = consolidatedStatus?.state;
    return state != PegTxState.done;
  }

  /// A pending settlement is a peg that is in the processing, exchanging, or sending state,
  /// ie. the user has PAID and the peg is waiting to be completed.
  bool get isPendingSettlement {
    final state = consolidatedStatus?.state;
    return state == PegTxState.insufficientAmount ||
        state == PegTxState.detected ||
        state == PegTxState.processing;
  }
}

/// For pegs, Sideswap returns a list of deposit transactions each with their own status.
/// This class consolidates the statuses into a single object, choosing the most relevant transaction.
/// For Aqua controlled pegs, this will be the only transaction.
/// For External user controlled pegs, this will the the most relevant transaction (the one with the most advanced status).
@freezed
class ConsolidatedPegStatus with _$ConsolidatedPegStatus {
  const factory ConsolidatedPegStatus({
    PegTxState? state,
    PegStatusTxns? transaction,
    dynamic detectedConfs,
    dynamic totalConfs,
  }) = _ConsolidatedPegStatus;

  factory ConsolidatedPegStatus.fromJson(Map<String, dynamic> json) =>
      _$ConsolidatedPegStatusFromJson(json);
}

/// TODO: This is a temporary solution to provide a single overall state.
/// The long-term fix involves showing a list of all deposit
/// txs with their individual statuses.
/// Multiple txs would be an edge cases anyway. Aqua controlled pegs will ohly send one tx per order.
/// Multiple txs would only come from External Peg-in/out
///
/// Priority order: Done > Processing > Detected > InsufficientAmount
extension ConsolidatedPegStatusX on SwapPegStatusResult {
  ConsolidatedPegStatus getConsolidatedStatus() {
    if (transactions.isEmpty) {
      _logger.debug('[Sideswap][PegStatus] Transactions are empty');
      return const ConsolidatedPegStatus(state: null);
    }

    _logger.debug(
        '[Sideswap][PegStatus] Number of transactions: ${transactions.length}');
    final doneTxn =
        transactions.firstWhereOrNull((tx) => tx.txState == PegTxState.done);
    final processingTxn = transactions
        .firstWhereOrNull((tx) => tx.txState == PegTxState.processing);
    final detectedTxn = transactions
        .firstWhereOrNull((tx) => tx.txState == PegTxState.detected);
    final insufficientAmountTxn = transactions
        .firstWhereOrNull((tx) => tx.txState == PegTxState.insufficientAmount);

    if (doneTxn != null) {
      _logger.debug('[Sideswap][PegStatus] Found done transaction');
      return ConsolidatedPegStatus(
          state: PegTxState.done, transaction: doneTxn);
    }
    if (processingTxn != null) {
      _logger.debug(
          '[Sideswap][PegStatus] Found processing transaction. Confs: ${processingTxn.detectedConfs}/${processingTxn.totalConfs}');
      return ConsolidatedPegStatus(
        state: PegTxState.processing,
        transaction: processingTxn,
        detectedConfs: processingTxn.detectedConfs,
        totalConfs: processingTxn.totalConfs,
      );
    }
    if (detectedTxn != null) {
      _logger.debug('[Sideswap][PegStatus] Found detected transaction');
      return ConsolidatedPegStatus(
          state: PegTxState.detected, transaction: detectedTxn);
    }
    if (insufficientAmountTxn != null) {
      _logger
          .debug('[Sideswap][PegStatus] Found insufficient amount transaction');
      return ConsolidatedPegStatus(
          state: PegTxState.insufficientAmount,
          transaction: insufficientAmountTxn);
    }

    _logger.debug('[Sideswap][PegStatus] No relevant transaction found');
    return const ConsolidatedPegStatus(state: null);
  }
}
