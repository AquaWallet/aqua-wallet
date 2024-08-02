import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_status.freezed.dart';

@freezed
class ConnectionStatus with _$ConnectionStatus {
  const factory ConnectionStatus({
    required bool? isDeviceConnected,
    required int? lastBitcoinBlock,
    required int? lastLiquidBlock,
    required bool initialized,
  }) = _ConnectionStatus;
}
