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

extension RegionsStatic on Region {
  static final Region us = Region(name: 'United States of America', iso: 'US');
  static final Region ca = Region(name: 'Canada', iso: 'CA');
  static final Region mx = Region(name: 'Mexico', iso: 'MX');
  static final Region br = Region(name: 'Brazil', iso: 'BR');

  // European countries
  static final Region ad = Region(name: 'Andorra', iso: 'AD');
  static final Region at = Region(name: 'Austria', iso: 'AT');
  static final Region be = Region(name: 'Belgium', iso: 'BE');
  static final Region bg = Region(name: 'Bulgaria', iso: 'BG');
  static final Region hr = Region(name: 'Croatia', iso: 'HR');
  static final Region cz = Region(name: 'Czech Republic', iso: 'CZ');
  static final Region dk = Region(name: 'Denmark', iso: 'DK');
  static final Region ee = Region(name: 'Estonia', iso: 'EE');
  static final Region fi = Region(name: 'Finland', iso: 'FI');
  static final Region fr = Region(name: 'France', iso: 'FR');
  static final Region de = Region(name: 'Germany', iso: 'DE');
  static final Region gr = Region(name: 'Greece', iso: 'GR');
  static final Region hu = Region(name: 'Hungary', iso: 'HU');
  static final Region is_ = Region(name: 'Iceland', iso: 'IS');
  static final Region it = Region(name: 'Italy', iso: 'IT');
  static final Region lv = Region(name: 'Latvia', iso: 'LV');
  static final Region li = Region(name: 'Liechtenstein', iso: 'LI');
  static final Region lt = Region(name: 'Lithuania', iso: 'LT');
  static final Region lu = Region(name: 'Luxembourg', iso: 'LU');
  static final Region md = Region(name: 'Moldova', iso: 'MD');
  static final Region me = Region(name: 'Montenegro', iso: 'ME');
  static final Region nl = Region(name: 'Netherlands', iso: 'NL');
  static final Region mk = Region(name: 'North Macedonia', iso: 'MK');
  static final Region no = Region(name: 'Norway', iso: 'NO');
  static final Region pl = Region(name: 'Poland', iso: 'PL');
  static final Region pt = Region(name: 'Portugal', iso: 'PT');
  static final Region ro = Region(name: 'Romania', iso: 'RO');
  static final Region sm = Region(name: 'San Marino', iso: 'SM');
  static final Region rs = Region(name: 'Serbia', iso: 'RS');
  static final Region sk = Region(name: 'Slovakia', iso: 'SK');
  static final Region si = Region(name: 'Slovenia', iso: 'SI');
  static final Region es = Region(name: 'Spain', iso: 'ES');
  static final Region se = Region(name: 'Sweden', iso: 'SE');
  static final Region ch = Region(name: 'Switzerland', iso: 'CH');
}
