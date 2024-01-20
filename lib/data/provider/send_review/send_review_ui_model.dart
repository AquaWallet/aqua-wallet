import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_review_ui_model.freezed.dart';

@freezed
class SendReviewUiModel with _$SendReviewUiModel {
  const factory SendReviewUiModel.success({
    required List<SendReviewItemUiModel> items,
  }) = SendReviewSuccessUiModel;
}

@freezed
class SendReviewItemUiModel with _$SendReviewItemUiModel {
  const factory SendReviewItemUiModel.details({
    required String amount,
    required String address,
  }) = SendReviewDetailsItemUiModel;
  const factory SendReviewItemUiModel.memo() = SendReviewMemoItemUiModel;
  const factory SendReviewItemUiModel.spacer() = SendReviewSpacerItemUiModel;
  const factory SendReviewItemUiModel.button() = SendReviewButtonItemUiModel;
}

@freezed
class SendReviewFeeUiModel with _$SendReviewFeeUiModel {
  const factory SendReviewFeeUiModel.success({
    required String value,
  }) = SendReviewFeeSuccessUiModel;
  const factory SendReviewFeeUiModel.loading() = SendReviewFeeLoadingUiModel;
  const factory SendReviewFeeUiModel.error({
    required String title,
  }) = SendReviewFeeErrorUiModel;
}

@freezed
class SendReviewInsufficientFeeUiModel with _$SendReviewInsufficientFeeUiModel {
  const factory SendReviewInsufficientFeeUiModel.success({
    required String requiredFeeLbtc,
    required String requiredFeeUsdt,
    required String currentLbtcBalance,
    required String currentUsdtBalance,
  }) = SendReviewInsufficientFeeSuccessUiModel;
}
