import 'package:aqua/features/settings/settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sideswap_state.freezed.dart';
part 'sideswap_state.g.dart';

enum SwapUserInputSide {
  deliver,
  receive,
}

@freezed
class SideswapInputState with _$SideswapInputState {
  const factory SideswapInputState({
    required List<Asset> assets,
    Asset? deliverAsset,
    Asset? receiveAsset,
    @Default('') String deliverAmount,
    @Default('') String receiveAmount,
    @Default(0) int deliverAmountSatoshi,
    @Default(0) int receiveAmountSatoshi,
    @Default('') String deliverAssetBalance,
    @Default('') String receiveAssetBalance,
    @Default(SwapUserInputSide.deliver) SwapUserInputSide userInputSide,
    @Default(false) bool isFiat,
  }) = _SideswapInputState;

  factory SideswapInputState.fromJson(Map<String, dynamic> json) =>
      _$SideswapInputStateFromJson(json);
}

extension SideswapInputStateExt on SideswapInputState {
  int? get userInputSendAmount => userInputSide == SwapUserInputSide.deliver
      ? deliverAmountSatoshi <= 0
          ? null
          : deliverAmountSatoshi
      : null;

  int? get userInputReceiveAmount => userInputSide == SwapUserInputSide.receive
      ? receiveAmountSatoshi <= 0
          ? null
          : receiveAmountSatoshi
      : null;

  // Determine whether it is a peg-in or peg-out
  bool get isPegIn {
    if (deliverAsset == null || receiveAsset == null) {
      return false;
    }
    return deliverAsset!.isBTC && receiveAsset!.isLBTC;
  }

  // Determine whether it is a Peg or a Swap
  bool get isPeg {
    if (deliverAsset == null || receiveAsset == null) {
      return false;
    }
    final isBtcToLbtc = deliverAsset!.isBTC && receiveAsset!.isLBTC;
    final isLbtcToBtc = deliverAsset!.isLBTC && receiveAsset!.isBTC;
    return isBtcToLbtc || isLbtcToBtc;
  }

  bool get isSendAll {
    final balance = deliverAsset?.amount;
    return balance != null && balance == deliverAmountSatoshi;
  }
}
