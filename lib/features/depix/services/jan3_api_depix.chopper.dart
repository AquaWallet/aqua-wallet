// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jan3_api_depix.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$Jan3ApiDepix extends Jan3ApiDepix {
  _$Jan3ApiDepix([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = Jan3ApiDepix;

  @override
  Future<Response<EulenDepositResponse>> deposit(EulenDepositRequest request) {
    final Uri $url = Uri.parse('/api/v1/eulen/deposit/');
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<EulenDepositResponse, EulenDepositResponse>($request);
  }

  @override
  Future<Response<EulenDepositsResponse>> getDeposits() {
    final Uri $url = Uri.parse('/api/v1/eulen/deposits/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<EulenDepositsResponse, EulenDepositsResponse>($request);
  }

  @override
  Future<Response<EulenPixDepixFeeResponse>> getPixDepixFee() {
    final Uri $url = Uri.parse('/api/v1/eulen/pix-depix-fee/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client
        .send<EulenPixDepixFeeResponse, EulenPixDepixFeeResponse>($request);
  }
}
