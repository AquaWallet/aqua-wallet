import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'send_review_processing_result.freezed.dart';

@freezed
class SendReviewProcessingResult with _$SendReviewProcessingResult {
  const factory SendReviewProcessingResult.success({
    required int amount,
    required int fee,
    required String memo,
    required String address,
    required String txhash,
  }) = SendReviewSuccessProcessingResult;
  const factory SendReviewProcessingResult.loading({
    required String description,
  }) = SendReviewLoadingProcessingResult;
  const factory SendReviewProcessingResult.genericFailure({
    required String title,
    required String subtitle,
    required String buttonTitle,
    required Function() onButtonPressed,
  }) = SendReviewGenericFailureProcessingResult;
  const factory SendReviewProcessingResult.amountFailure({
    required String title,
    required String subtitle,
    required String cancelButtonTitle,
    required String getButtonTitle,
    required Function() onCancelButtonPressed,
    required Function() onGetButtonPressed,
  }) = SendReviewAmountFailureProcessingResult;
}
