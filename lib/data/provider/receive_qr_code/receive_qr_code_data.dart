import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'receive_qr_code_data.freezed.dart';

@freezed
class ReceiveQrCodeData with _$ReceiveQrCodeData {
  const factory ReceiveQrCodeData({
    required String address,
    required String qrImageData,
  }) = _ReceiveQrCodeData;
}
