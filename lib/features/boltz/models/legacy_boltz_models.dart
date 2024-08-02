import 'package:aqua/features/boltz/boltz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'legacy_boltz_models.freezed.dart';
part 'legacy_boltz_models.g.dart';

/// Caches the normal swap request, response, and secure data
@Deprecated('Replaced by LbtcLnV2Swap from Boltz Dart package')
@freezed
class BoltzSwapData with _$BoltzSwapData {
  const factory BoltzSwapData({
    DateTime? created,
    required BoltzCreateSwapRequest request,
    required BoltzCreateSwapResponse response,
    required BoltzSwapSecureData secureData,
    BoltzGetPairsResponse? fees,
    @BoltzSwapStatusConverter()
    @Default(BoltzSwapStatus.created)
    BoltzSwapStatus swapStatus,
    String? onchainTxHash,
    String? refundTx,
  }) = _BoltzSwapData;

  factory BoltzSwapData.fromJson(Map<String, dynamic> json) =>
      _$BoltzSwapDataFromJson(json);
}

/// Caches the reverse swap request, response, secure data, and added data we need for the claim tx
@Deprecated('Replaced by LbtcLnV2Swap from Boltz Dart package')
@freezed
class BoltzReverseSwapData with _$BoltzReverseSwapData {
  const factory BoltzReverseSwapData({
    DateTime? created,
    required BoltzCreateReverseSwapRequest request,
    required BoltzCreateReverseSwapResponse response,
    required BoltzSwapSecureData secureData,
    BoltzGetPairsResponse? fees,
    @BoltzSwapStatusConverter()
    @Default(BoltzSwapStatus.created)
    BoltzSwapStatus swapStatus,
    String? claimTx,
  }) = _BoltzReverseSwapData;

  factory BoltzReverseSwapData.fromJson(Map<String, dynamic> json) =>
      _$BoltzReverseSwapDataFromJson(json);
}

extension BoltzReverseSwapDataExt on BoltzReverseSwapData {
  String? get onchainTxHash => claimTx;
}
