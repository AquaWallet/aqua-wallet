// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_flags_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$FeatureFlagsService extends FeatureFlagsService {
  _$FeatureFlagsService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = FeatureFlagsService;

  @override
  Future<Response<List<ServiceTilesResponse>>> getMarketPlaceTiles({
    String? buildNumber,
    String? region,
  }) {
    final Uri $url = Uri.parse('/api/v1/marketplace/tiles');
    final Map<String, dynamic> $params = <String, dynamic>{
      'build': buildNumber,
      'region': region,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client
        .send<List<ServiceTilesResponse>, ServiceTilesResponse>($request);
  }

  @override
  Future<Response<List<FeatureFlag>>> getFlags() {
    final Uri $url = Uri.parse('/api/v1/config/flags/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<List<FeatureFlag>, FeatureFlag>($request);
  }

  @override
  Future<Response<List<SwitchType>>> getSwitches() {
    final Uri $url = Uri.parse('/api/v1/config/switches/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<List<SwitchType>, SwitchType>($request);
  }
}
