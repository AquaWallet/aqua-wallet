import 'package:freezed_annotation/freezed_annotation.dart';

part 'sideshift_quote.freezed.dart';
part 'sideshift_quote.g.dart';

@freezed
class SideshiftQuoteRequest with _$SideshiftQuoteRequest {
  factory SideshiftQuoteRequest({
    String? depositCoin,
    String? depositNetwork,
    String? settleCoin,
    String? settleNetwork,
    String? depositAmount,
    String? settleAmount,
    String? affiliateId,
    String? commissionRate,
  }) = _SideshiftQuoteRequest;

  factory SideshiftQuoteRequest.fromJson(Map<String, dynamic> json) =>
      _$SideshiftQuoteRequestFromJson(json);
}

@freezed
class SideshiftQuoteResponse with _$SideshiftQuoteResponse {
  factory SideshiftQuoteResponse({
    required String id,
    DateTime? createdAt,
    String? depositCoin,
    String? settleCoin,
    String? depositNetwork,
    String? settleNetwork,
    DateTime? expiresAt,
    String? depositAmount,
    String? settleAmount,
    String? rate,
    String? affiliateId,
  }) = _SideshiftQuoteResponse;

  factory SideshiftQuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftQuoteResponseFromJson(json);
}
