import 'package:aqua/features/send/send.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_asset_transaction_execution_state.freezed.dart';

@freezed
class SendAssetTransactionState with _$SendAssetTransactionState {
  const factory SendAssetTransactionState.idle() = SendAssetTransactionIdle;
  const factory SendAssetTransactionState.created({
    required SendAssetOnchainTx tx,
  }) = SendAssetTransactionCreated;
  const factory SendAssetTransactionState.complete({
    required SendAssetCompletionArguments args,
  }) = SendAssetTransactionComplete;
}
