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

extension RegionExt on Region {
  String get flagSvg {
    const ext = '.svg';
    final filename = name
        // Remove text in parentheses AND any commas, periods, or apostrophes
        .replaceAll(RegExp(r"\(([^)]+)\)|[,.']"), '')
        // Replace spaces with hyphens and remove any double hyphens
        .replaceAll(' ', '-')
        // Remove any double hyphens
        .replaceAll('--', '-')
        .toLowerCase();
    // If the filename ends with a hyphen, remove it
    final filenameWithExt = '$filename$ext'.replaceAll('-$ext', ext);
    return 'assets/flags/$filenameWithExt';
  }
}
