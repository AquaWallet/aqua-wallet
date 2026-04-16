import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ui_components/ui_components.dart';

part 'receive_amount_input_state.freezed.dart';

@freezed
class ReceiveAmountInputState with _$ReceiveAmountInputState {
  const factory ReceiveAmountInputState({
    required Asset asset,
    SwapPair? swapPair,
    String? amountFieldText,
    @Default(0) int amountInSats,
    @Default(0) int balanceInSats,
    @Default('') String balanceDisplay,
    required String displayConversionAmount,
    required ExchangeRate rate,
    @Default(AquaAssetInputUnit.crypto) AquaAssetInputUnit cryptoUnit,
    @Default(AquaAssetInputType.crypto) AquaAssetInputType inputType,
  }) = _ReceiveAmountInputState;
}

extension ReceiveAmountInputStateX on ReceiveAmountInputState {
  bool get isSatsUnit => cryptoUnit == AquaAssetInputUnit.sats;
  bool get isCryptoUnit => cryptoUnit == AquaAssetInputUnit.crypto;
  bool get isBitsUnit => cryptoUnit == AquaAssetInputUnit.bits;
  bool get isCryptoInput => inputType == AquaAssetInputType.crypto;
  bool get isFiatInput => inputType == AquaAssetInputType.fiat;
}
