// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jan3_api_token_refresh.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$Jan3ApiTokenlessService extends Jan3ApiTokenlessService {
  _$Jan3ApiTokenlessService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = Jan3ApiTokenlessService;

  @override
  Future<Response<AccessTokenResponse>> refresh(RefreshTokenRequest request) {
    final Uri $url = Uri.parse('/api/v1/auth/refresh/');
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<AccessTokenResponse, AccessTokenResponse>($request);
  }
}
