// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marketplace_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$MarketplaceService extends MarketplaceService {
  _$MarketplaceService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = MarketplaceService;

  @override
  Future<Response<List<ServiceTilesResponse>>> getMarketPlaceTiles({
    String? buildNumber,
    String? os,
  }) {
    final Uri $url = Uri.parse('/api/v1/marketplace/tiles');
    final Map<String, dynamic> $params = <String, dynamic>{
      'build': buildNumber,
      'os': os,
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
  Future<Response<RegionResponse>> fetchRegions() {
    final Uri $url = Uri.parse('/api/v1/marketplace/regions');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<RegionResponse, RegionResponse>($request);
  }

  @override
  Future<Response<AssetsResponse>> fetchAssets() {
    final Uri $url = Uri.parse('/api/v1/marketplace/assets');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<AssetsResponse, AssetsResponse>($request);
  }

  @override
  Future<Response<AssetsResponse>> fetchTestNetAssets() {
    final Uri $url = Uri.parse('/api/v1/marketplace/assets/testnet');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<AssetsResponse, AssetsResponse>($request);
  }
}
