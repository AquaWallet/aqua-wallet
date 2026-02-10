import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_status.freezed.dart';

@freezed
class SyncStatus with _$SyncStatus {
  const factory SyncStatus({
    required bool? isDeviceConnected,
    required int? lastBitcoinBlock,
    required int? lastLiquidBlock,
    required bool initialized,
  }) = _SyncStatus;
}
