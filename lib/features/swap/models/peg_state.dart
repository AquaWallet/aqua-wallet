import 'package:aqua/features/swap/swap.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'peg_state.freezed.dart';

@freezed
class PegState with _$PegState {
  const factory PegState.empty() = PegStateEmpty;
  const factory PegState.pendingVerification({
    required SwapPegReviewModel data,
  }) = PegStateVerify;
  const factory PegState.success() = PegStateSuccess;
}
