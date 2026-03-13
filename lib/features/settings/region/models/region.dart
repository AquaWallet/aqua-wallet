import 'package:freezed_annotation/freezed_annotation.dart';

part 'region.freezed.dart';
part 'region.g.dart';

@freezed
class RegionResponse with _$RegionResponse {
  factory RegionResponse({
    @JsonKey(name: 'QueryResponse') RegionList? data,
  }) = _RegionResponse;

  factory RegionResponse.fromJson(Map<String, dynamic> json) =>
      _$RegionResponseFromJson(json);
}

extension RegionResponseExt on RegionResponse {
  List<Region> get regions => data?.regions ?? [];
}

@freezed
class RegionList with _$RegionList {
  factory RegionList({
    @Default([]) @JsonKey(name: 'Regions') List<Region> regions,
  }) = _RegionList;

  factory RegionList.fromJson(Map<String, dynamic> json) =>
      _$RegionListFromJson(json);
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
  String get flagSvg => FlagHelper.getFlagPath(iso, name);
}

/// Helper class for flag file resolution
class FlagHelper {
  static const _basePath = 'assets/flags/';

  /// Map of ISO codes to flag filenames
  static const _isoToFileName = {
    // Special naming cases
    'SH': 'saint-helena',
    'KR': 'republic-of-korea',
    'MD': 'republic-of-moldova',
    'GB': 'united-kingdom',
    'US': 'united-states-of-america',
    'EU': 'european-union',
    'CZ': 'czechia',
    'TZ': 'tanzania',
    'VG': 'british-virgin-islands',
    'VI': 'virgin-islands',
    'BL': 'st-barthelemy',
    'ST': 'sao-tome-principe',

    // All currencies from exchange_rate.dart
    'CA': 'canada',
    'MX': 'mexico',
    'RU': 'russia',
    'DK': 'denmark',
    'IL': 'israel',
    'MY': 'malaysia',
    'NG': 'nigeria',
    'NO': 'norway',
    'NZ': 'new-zealand',
    'PL': 'poland',
    'AU': 'australia',
    'BR': 'brazil',
    'CN': 'china',
    'HK': 'hong-kong',
    'IN': 'india',
    'JP': 'japan',
    'CH': 'switzerland',
    'SE': 'sweden',
    'SG': 'singapore',
    'TH': 'thailand',
    'TR': 'turkey',
    'VN': 'vietnam',
    'ZA': 'south-africa',
    'ES-CT': 'catalan',
  };

  /// Get flag SVG path from ISO code and optional country name
  static String getFlagPath(String iso, [String? countryName]) {
    final filename = _isoToFileName[iso] ??
        (countryName?.isNotEmpty == true
            ? _normalizeCountryName(countryName!)
            : null) ??
        'united-nations';

    return '$_basePath$filename.svg';
  }

  /// Normalize country name to filename format
  static String _normalizeCountryName(String name) {
    return name
        .replaceAll(RegExp(r"\(([^)]+)\)|[,.']"), '')
        .replaceAll(' ', '-')
        .replaceAll('--', '-')
        .toLowerCase()
        .replaceAll(RegExp(r'-$'), '');
  }
}

extension RegionEuroExt on Region {
  bool get usesEuro {
    const euroIsos = {
      'AT',
      'BE',
      'BG',
      'HR',
      'EE',
      'FI',
      'FR',
      'DE',
      'GR',
      'IT',
      'LV',
      'LT',
      'LU',
      'NL',
      'PT',
      'SK',
      'SI',
      'ES',
      'AD',
      'SM',
      'ME',
    };
    return euroIsos.contains(iso);
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
  static final Region cn = Region(name: 'China', iso: 'CN');
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
  static final Region sq = Region(name: 'Albania', iso: 'AL');
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
  static final Region sa = Region(name: 'Saudi Arabia', iso: 'SA');
  static final Region sk = Region(name: 'Slovakia', iso: 'SK');
  static final Region si = Region(name: 'Slovenia', iso: 'SI');
  static final Region es = Region(name: 'Spain', iso: 'ES');
  static final Region catalonia = Region(name: 'Catalonia', iso: 'ES-CT');
  static final Region se = Region(name: 'Sweden', iso: 'SE');
  static final Region ch = Region(name: 'Switzerland', iso: 'CH');
  static final Region th = Region(name: 'Thailand', iso: 'TH');
}
