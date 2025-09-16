import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart'; 

part 'legacy_boltz_models.freezed.dart';
part 'legacy_boltz_models.g.dart';

/// Caches the normal swap request, response, and secure data
@Deprecated('Replaced by LbtcLnV2Swap from Boltz Dart package')
@freezed
class BoltzSwapData with _$BoltzSwapData {
  const factory BoltzSwapData({
    DateTime? created,
    @JsonKey(
      fromJson: _requestFromJson,
      toJson: _requestToJson,
    )
    required BoltzCreateSwapRequest request,
    @JsonKey(
      fromJson: _responseFromJson,
      toJson: _responseToJson,
    )
    required BoltzCreateSwapResponse response,
    required BoltzSwapSecureData secureData,
    @JsonKey(
      fromJson: _feesFromJson,
      toJson: _feesToJson,
    )
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
    @JsonKey(
      fromJson: _reverseRequestFromJson,
      toJson: _reverseRequestToJson,
    )
    required BoltzCreateReverseSwapRequest request,
    @JsonKey(
      fromJson: _reverseResponseFromJson,
      toJson: _reverseResponseToJson,
    )
    required BoltzCreateReverseSwapResponse response,
    required BoltzSwapSecureData secureData,
    @JsonKey(
      fromJson: _feesFromJson,
      toJson: _feesToJson,
    )
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

// Helper functions for JSON serialization
BoltzCreateSwapRequest _requestFromJson(Map<String, dynamic> json) =>
    BoltzCreateSwapRequest.fromJson(json);

Map<String, dynamic> _requestToJson(BoltzCreateSwapRequest request) =>
    request.toJson();

BoltzCreateSwapResponse _responseFromJson(Map<String, dynamic> json) =>
    BoltzCreateSwapResponse.fromJson(json);

Map<String, dynamic> _responseToJson(BoltzCreateSwapResponse response) =>
    response.toJson();

BoltzGetPairsResponse? _feesFromJson(Map<String, dynamic>? json) =>
    json != null ? BoltzGetPairsResponse.fromJson(json) : null;

Map<String, dynamic>? _feesToJson(BoltzGetPairsResponse? fees) =>
    fees?.toJson();

BoltzCreateReverseSwapRequest _reverseRequestFromJson(Map<String, dynamic> json) =>
    BoltzCreateReverseSwapRequest.fromJson(json);

Map<String, dynamic> _reverseRequestToJson(BoltzCreateReverseSwapRequest request) =>
    request.toJson();

BoltzCreateReverseSwapResponse _reverseResponseFromJson(Map<String, dynamic> json) =>
    BoltzCreateReverseSwapResponse.fromJson(json);

Map<String, dynamic> _reverseResponseToJson(BoltzCreateReverseSwapResponse response) =>
    response.toJson();
