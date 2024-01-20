import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';

part 'send_asset_validation_parameters.freezed.dart';

@freezed
class SendAssetValidationParams with _$SendAssetValidationParams {
  const factory SendAssetValidationParams({
    required Asset asset,
    String? address,
    int? amount,
    int? balance,
  }) = _SendAssetValidationParams;
}
