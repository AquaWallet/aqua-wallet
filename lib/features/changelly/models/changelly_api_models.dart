import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:coin_cz/features/changelly/models/changelly_models.dart';

part 'changelly_api_models.freezed.dart';
part 'changelly_api_models.g.dart';

@freezed
class ChangellyCurrencyListResponse with _$ChangellyCurrencyListResponse {
  const factory ChangellyCurrencyListResponse({
    required List<String> result,
  }) = _ChangellyCurrencyListResponse;

  factory ChangellyCurrencyListResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangellyCurrencyListResponseFromJson(json);
}

@freezed
class ChangellyPairsResponse with _$ChangellyPairsResponse {
  const factory ChangellyPairsResponse({
    required List<ChangellyPair> pairs,
  }) = _ChangellyPairsResponse;

  factory ChangellyPairsResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangellyPairsResponseFromJson(json);
}

@freezed
class ChangellyQuoteListResponse with _$ChangellyQuoteListResponse {
  const factory ChangellyQuoteListResponse({
    required List<ChangellyQuoteResponse> quotes,
  }) = _ChangellyQuoteListResponse;

  factory ChangellyQuoteListResponse.fromJson(List<dynamic> json) =>
      ChangellyQuoteListResponse(
        quotes: json
            .map((e) =>
                ChangellyQuoteResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
