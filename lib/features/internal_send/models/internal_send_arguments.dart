import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'internal_send_arguments.freezed.dart';

@freezed
class InternalSendArguments with _$InternalSendArguments {
  const factory InternalSendArguments.amount({
    required Asset deliverAsset,
    required Asset receiveAsset,
    double? amount,
  }) = InternalSendAmountArguments;
  const factory InternalSendArguments.pegReview({
    required Asset deliverAsset,
    required Asset receiveAsset,
    required SwapPegReviewModel peg,
  }) = InternalSendPegReviewArguments;
  const factory InternalSendArguments.swapReview({
    required Asset deliverAsset,
    required Asset receiveAsset,
    required SwapStartWebResponse swap,
  }) = InternalSendSwapReviewArguments;
  const factory InternalSendArguments.pegSuccess({
    required PegStateSuccess state,
  }) = InternalSendPegSuccessArguments;
  const factory InternalSendArguments.swapSuccess({
    required SwapStateSuccess state,
  }) = InternalSendSwapSuccessArguments;
}

extension InternalSendArgumentsX on InternalSendArguments {
  Asset get deliverAsset => maybeMap(
        amount: (s) => s.deliverAsset,
        pegReview: (s) => s.deliverAsset,
        swapReview: (s) => s.deliverAsset,
        orElse: () => throw ArgumentError('Invalid state'),
      );

  Asset get receiveAsset => maybeMap(
        amount: (s) => s.receiveAsset,
        pegReview: (s) => s.receiveAsset,
        swapReview: (s) => s.receiveAsset,
        orElse: () => throw ArgumentError('Invalid state'),
      );
}
