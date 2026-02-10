import 'package:aqua/data/data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rbf_state.freezed.dart';

@freezed
class RbfInputState with _$RbfInputState {
  const factory RbfInputState({
    required GdkTransaction transaction,
    required int transactionVsize,
    required int feeRate,
    required int minFeeRate,
    required int feeAmount,
    required String feeInFiat,
  }) = _RbfInputState;
}
