import 'package:coin_cz/features/address_validator/address_validation.dart';
import 'package:coin_cz/features/lightning/lnurl_parser/dart_lnurl_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_scanner_pop_result.freezed.dart';

@freezed
class QrScannerPopResult with _$QrScannerPopResult {
  const factory QrScannerPopResult.send({
    required ParsedAddress parsedAddress,
  }) = QrScannerPopSendResult;
  const factory QrScannerPopResult.lnurlWithdraw({
    required LNURLParseResult lnurlParseResult,
  }) = QrScannerPopLnurlWithdrawResult;
  const factory QrScannerPopResult.swap({
    required String orderId,
    required String sendAsset,
    required int sendAmount,
    required String recvAsset,
    required int recvAmount,
    required String uploadUrl,
  }) = QrScannerPopSwapResult;
  const factory QrScannerPopResult.samRock({
    required List<String> setupChains,
    required String otp,
    required String uploadUrl,
  }) = QrScannerPopSamRockResult;
  const factory QrScannerPopResult.requiresRestart() =
      QrScannerPopRequiresRestartResult;
  const factory QrScannerPopResult.empty() = QrScannerPopEmptyResult;
}
