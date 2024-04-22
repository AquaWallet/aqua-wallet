import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_status_state.freezed.dart';

@freezed
class AssetConnectivityState with _$AssetConnectivityState {
  const factory AssetConnectivityState({
    required bool? isDeviceConnected,
    required int? lastBitcoinBlock,
    required int? lastLiquidBlock,
    required bool initialized,
  }) = _AssetConnectivityState;
}
