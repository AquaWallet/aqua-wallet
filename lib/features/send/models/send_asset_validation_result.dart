import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_asset_validation_result.freezed.dart';

@freezed
class SendAssetValidationResult with _$SendAssetValidationResult {
  const factory SendAssetValidationResult.valid() = _Valid;

  const factory SendAssetValidationResult.invalid({
    required ExceptionLocalized error,
    required String balanceDisplay,
  }) = _Invalid;
}
