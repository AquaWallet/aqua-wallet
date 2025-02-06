import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_scan_state.freezed.dart';

@freezed
class QrScanState with _$QrScanState {
  const factory QrScanState.idle() = _Idle;
  const factory QrScanState.unknownQrCode(String? code) = _UnknownQrCode;
  const factory QrScanState.pullSendAsset(SendAssetArguments args) =
      _PullSendAsset;
  const factory QrScanState.pushSendAsset(SendAssetArguments args) =
      _PushSendAsset;
  const factory QrScanState.lnurlWithdraw(
      LNURLWithdrawParams? withdrawalParams) = _LnurlWithdraw;
}
