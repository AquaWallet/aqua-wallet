import 'package:coin_cz/features/lightning/lightning.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_scan_state.freezed.dart';

@freezed
class TextScanState with _$TextScanState {
  const factory TextScanState.idle() = _Idle;

  const factory TextScanState.loading() = _Loading;

  const factory TextScanState.error([String? message]) = _Error;
  const factory TextScanState.unknownText(String recognizedText) = _UnknownText;

  const factory TextScanState.pullSendAsset(SendAssetArguments args) =
      _PullSendAsset;
  const factory TextScanState.pushSendAsset(SendAssetArguments args) =
      _PushSendAsset;

  const factory TextScanState.rawValue(String raw) = _RawValue;

  const factory TextScanState.multipleRawValue(List<String> rawValues) =
      _MultipleRawValue;

  const factory TextScanState.addressSelection(List<String> addresses) =
      _TextScanStateAddressSelection;

  const factory TextScanState.lnurlWithdraw(
      LNURLWithdrawParams? withdrawalParams) = _LnurlWithdraw;
}
