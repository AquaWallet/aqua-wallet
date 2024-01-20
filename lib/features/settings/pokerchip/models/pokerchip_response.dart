import 'package:freezed_annotation/freezed_annotation.dart';

part 'pokerchip_response.freezed.dart';
part 'pokerchip_response.g.dart';

@freezed
class PokerChipAssetResponse with _$PokerChipAssetResponse {
  factory PokerChipAssetResponse({
    String? txid,
    int? vout,
    Status? status,
    required int value,
    required String asset,
  }) = _PokerChipAssetResponse;

  factory PokerChipAssetResponse.fromJson(Map<String, dynamic> json) =>
      _$PokerChipAssetResponseFromJson(json);
}

@freezed
class Status with _$Status {
  factory Status({
    bool? confirmed,
    @JsonKey(name: 'block_height') int? blockHeight,
    @JsonKey(name: 'block_hash') String? blockHash,
    @JsonKey(name: 'block_time') int? blockTime,
  }) = _Status;

  factory Status.fromJson(Map<String, dynamic> json) => _$StatusFromJson(json);
}
