import 'package:freezed_annotation/freezed_annotation.dart';

part 'boltz_create_reverse_swap_response.freezed.dart';
part 'boltz_create_reverse_swap_response.g.dart';

/// Response body for `POST /createswap` type `reverse`

@freezed
class BoltzCreateReverseSwapResponse with _$BoltzCreateReverseSwapResponse {
  const factory BoltzCreateReverseSwapResponse({
    required String id,
    required String invoice,
    required String redeemScript,
    required String lockupAddress,
    required String blindingKey,
    required int timeoutBlockHeight,
    required int onchainAmount,
  }) = _BoltzCreateReverseSwapResponse;

  factory BoltzCreateReverseSwapResponse.fromJson(Map<String, dynamic> json) =>
      _$BoltzCreateReverseSwapResponseFromJson(json);
}
