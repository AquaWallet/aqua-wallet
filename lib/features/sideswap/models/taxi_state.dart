import 'package:aqua/data/models/gdk_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'taxi_state.freezed.dart';

@freezed
class TaxiState with _$TaxiState {
  const factory TaxiState.empty() = TaxiStateStateEmpty;

  /// Create initial pset
  const factory TaxiState.createPset({
    required String partiallySignedPset,
  }) = TaxiStateCreatePset;

  /// Sign our inputs
  const factory TaxiState.clientSignedPset({
    required GdkNewTransactionReply fullySignedPset,
  }) = TaxiStateClientSignedPset;

  /// Create final pset
  const factory TaxiState.finalSignedPset({
    required String finalSignedPset,
  }) = TaxiStateFinalSignedPset;

  /// Broadcast tx
  const factory TaxiState.broadcastTxSuccess({
    required String txId,
  }) = TaxiStateBroadcastTxSuccess;
}
