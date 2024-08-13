import 'package:freezed_annotation/freezed_annotation.dart';

part 'sideshift_transaction_state.freezed.dart';

@freezed
class SideshiftTransactionState with _$SideshiftTransactionState {
  const factory SideshiftTransactionState.complete() = _TransactionComplete;
  const factory SideshiftTransactionState.loading() = TransactionLoading;
}
