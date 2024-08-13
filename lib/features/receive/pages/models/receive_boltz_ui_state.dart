import 'package:boltz_dart/boltz_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receive_boltz_ui_state.freezed.dart';

// Create a dart Freezed class wil json serialization
@freezed
class ReceiveBoltzState with _$ReceiveBoltzState {
  const factory ReceiveBoltzState.enterAmount() = _EnterAmountState;
  const factory ReceiveBoltzState.generatingInvoice() = _GenInvoiceState;
  const factory ReceiveBoltzState.qrCode(LbtcLnSwap? swap) = _QrCodeState;
  const factory ReceiveBoltzState.success(int amountSats) = _SuccessState;
}

extension ReceiveBoltzStateExt on ReceiveBoltzState {
  bool get isSuccess => this is _SuccessState;

  bool get isAmountEntry => this is _EnterAmountState;

  bool get isGeneratingInvoice => this is _GenInvoiceState;

  bool get isLightningView =>
      this is _EnterAmountState || this is _GenInvoiceState;
}
