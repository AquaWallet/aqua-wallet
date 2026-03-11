// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mempool_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$MempoolApiService extends MempoolApiService {
  _$MempoolApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = MempoolApiService;

  @override
  Future<Response<String>> getLatestBlockHeight() {
    final Uri $url = Uri.parse('/api/blocks/tip/height');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<String, String>($request);
  }
}
