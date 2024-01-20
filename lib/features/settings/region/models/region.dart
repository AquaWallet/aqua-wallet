import 'package:freezed_annotation/freezed_annotation.dart';

part 'region.freezed.dart';
part 'region.g.dart';

@freezed
class RegionResponse with _$RegionResponse {
  factory RegionResponse({
    @JsonKey(name: 'QueryResponse') Response? data,
  }) = _RegionResponse;

  factory RegionResponse.fromJson(Map<String, dynamic> json) =>
      _$RegionResponseFromJson(json);
}

@freezed
class Response with _$Response {
  factory Response({
    @Default([]) @JsonKey(name: 'Regions') List<Region> regions,
  }) = _Response;

  factory Response.fromJson(Map<String, dynamic> json) =>
      _$ResponseFromJson(json);
}

@freezed
class Region with _$Region {
  factory Region({
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'ISO') required String iso,
  }) = _Region;

  factory Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);
}
