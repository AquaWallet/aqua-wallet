import 'package:aqua/features/settings/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_scanner_pop_result.freezed.dart';

@freezed
class QrScannerPopResult with _$QrScannerPopResult {
  const factory QrScannerPopResult.success({
    required String address,
    Asset? asset,
    String? amount,
    String? label,
    String? message,
  }) = QrScannerPopSuccessResult;
  const factory QrScannerPopResult.swap({
    required String orderId,
    required String sendAsset,
    required int sendAmount,
    required String recvAsset,
    required int recvAmount,
    required String uploadUrl,
  }) = QrScannerPopSwapResult;
  const factory QrScannerPopResult.requiresRestart() =
      QrScannerPopRequiresRestartResult;
  const factory QrScannerPopResult.empty() = QrScannerPopEmptyResult;
}
