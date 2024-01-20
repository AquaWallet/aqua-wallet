import 'package:aqua/features/settings/settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receive_qr_code_arguments.freezed.dart';

@freezed
class ReceiveQrCodeArguments with _$ReceiveQrCodeArguments {
  const factory ReceiveQrCodeArguments({
    required String id,
    required Asset asset,
    @Default(false) bool isGenericAsset,
  }) = _ReceiveQrCodeArguments;
}
