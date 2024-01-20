import 'package:freezed_annotation/freezed_annotation.dart';

part 'boltz_create_swap_response.freezed.dart';
part 'boltz_create_swap_response.g.dart';

/// Response body for `POST /createswap` type `normal`

@freezed
class BoltzCreateSwapResponse with _$BoltzCreateSwapResponse {
  const factory BoltzCreateSwapResponse({
    required String id,
    required String bip21,
    required String address,
    required String blindingKey,
    required String redeemScript,
    required bool acceptZeroConf,
    required int expectedAmount,
    required int timeoutBlockHeight,
  }) = _BoltzCreateSwapResponse;

  factory BoltzCreateSwapResponse.fromJson(Map<String, dynamic> json) =>
      _$BoltzCreateSwapResponseFromJson(json);
}
