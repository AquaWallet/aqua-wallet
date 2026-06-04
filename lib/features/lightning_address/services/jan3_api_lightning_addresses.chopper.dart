// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jan3_api_lightning_addresses.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$Jan3ApiLightningAddresses extends Jan3ApiLightningAddresses {
  _$Jan3ApiLightningAddresses([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = Jan3ApiLightningAddresses;

  @override
  Future<Response<IsLnUsernameAvailableResponse>> isLnUsernameAvailable(
      String username) {
    final Uri $url =
        Uri.parse('/api/v1/auth/user/ln-username/${username}/is-available');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<IsLnUsernameAvailableResponse,
        IsLnUsernameAvailableResponse>($request);
  }

  @override
  Future<Response<dynamic>> registerAddresses(
    RegisterAddressesRequest request, {
    bool overrideFingerprint = false,
  }) {
    final Uri $url = Uri.parse('/api/v1/auth/user/addresses/');
    final Map<String, dynamic> $params = <String, dynamic>{
      'override_fingerprint': overrideFingerprint
    };
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<PaymentResponse>> createPaymentRequest(
      PaymentRequest request) {
    final Uri $url =
        Uri.parse('/api/v1/liquid-wallet/payment-request/ln-username/');
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<PaymentResponse, PaymentResponse>($request);
  }

  @override
  Future<Response<List<LiquidWalletProduct>>> getProducts(String productType) {
    final Uri $url = Uri.parse('/api/v1/liquid-wallet/products/');
    final Map<String, dynamic> $params = <String, dynamic>{
      'product_type': productType
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client
        .send<List<LiquidWalletProduct>, LiquidWalletProduct>($request);
  }

  @override
  Future<Response<dynamic>> submitRawTx(SubmitSignedTxRequest request) {
    final Uri $url = Uri.parse('/api/v1/liquid-wallet/payment/submit-raw-tx/');
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
