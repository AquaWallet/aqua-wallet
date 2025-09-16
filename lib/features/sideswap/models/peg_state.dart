import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'peg_state.freezed.dart';

@freezed
class PegState with _$PegState {
  const factory PegState.empty() = PegStateEmpty;
  const factory PegState.pendingVerification({
    required SwapPegReviewModel data,
  }) = PegStateVerify;
  const factory PegState.success({
    required Asset asset,
    required GdkNewTransactionReply txn,
    required String orderId,
  }) = PegStateSuccess;
}

@freezed
class DirectPegState with _$DirectPegState {
  const factory DirectPegState.requestSent() = DirectPegStateRequestSent;
  const factory DirectPegState.orderCreated({
    required SwapStartPegResult order,
  }) = DirectPegStateOrderCreated;
}

extension PegStateExt on PegState? {
  bool get isSuccess => this is PegStateSuccess;
}
