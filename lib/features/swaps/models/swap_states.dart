import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'swap_models.dart';

part 'swap_states.freezed.dart';
part 'swap_states.g.dart';

@freezed
class SwapSetupState with _$SwapSetupState {
  const factory SwapSetupState({
    @Default(false) bool permissionsChecked,
    @Default([]) List<SwapAsset> availableAssets,
    @Default([]) List<SwapPair> availablePairs,
  }) = _SwapSetupState;

  factory SwapSetupState.fromJson(Map<String, dynamic> json) =>
      _$SwapSetupStateFromJson(json);
}

@freezed
class SwapOrderCreationState with _$SwapOrderCreationState {
  const factory SwapOrderCreationState({
    SwapPair? selectedPair,
    Decimal? amount,
    @Default(SwapOrderType.variable) SwapOrderType type,
    SwapRate? rate,
    SwapQuote? quote,
    SwapOrderRequest? orderRequest,
    SwapOrder? order,
  }) = _SwapOrderCreationState;

  factory SwapOrderCreationState.fromJson(Map<String, dynamic> json) =>
      _$SwapOrderCreationStateFromJson(json);
}

@freezed
class SwapStatusCheckState with _$SwapStatusCheckState {
  const factory SwapStatusCheckState({
    String? orderId,
    SwapOrderStatus? orderStatus,
  }) = _SwapStatusCheckState;

  factory SwapStatusCheckState.fromJson(Map<String, dynamic> json) =>
      _$SwapStatusCheckStateFromJson(json);
}
