import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:aqua/features/sideswap/models/sideswap.dart';

part 'peg_status_state.freezed.dart';
part 'peg_status_state.g.dart';

@freezed
class PegStatusState with _$PegStatusState {
  const factory PegStatusState({
    SwapPegStatusResult? fullStatus,
    ConsolidatedPegStatus? consolidatedStatus,
  }) = _PegStatusState;

  factory PegStatusState.fromJson(Map<String, dynamic> json) =>
      _$PegStatusStateFromJson(json);
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
