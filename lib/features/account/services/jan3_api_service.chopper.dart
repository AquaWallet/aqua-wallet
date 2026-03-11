// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jan3_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$Jan3ApiService extends Jan3ApiService {
  _$Jan3ApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = Jan3ApiService;

  @override
  Future<Response<MessageResponse>> login(LoginRequest request) {
    final Uri $url = Uri.parse('/api/v1/auth/login/');
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<MessageResponse, MessageResponse>($request);
  }

  @override
  Future<Response<AuthTokenResponse>> verify(VerifyRequest request) {
    final Uri $url = Uri.parse('/api/v1/auth/verify/');
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<AuthTokenResponse, AuthTokenResponse>($request);
  }

  @override
  Future<Response<AuthTokenResponse>> resetAccount() {
    final Uri $url = Uri.parse('/api/v1/auth/user/email-reset/');
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
    );
    return client.send<AuthTokenResponse, AuthTokenResponse>($request);
  }

  @override
  Future<Response<ProfileResponse>> getUser() {
    final Uri $url = Uri.parse('/api/v1/auth/user/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<ProfileResponse, ProfileResponse>($request);
  }

  @override
  Future<Response<ExchangeRateResponse>> getExchangeRates() {
    final Uri $url = Uri.parse('/api/v1/exrates/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<ExchangeRateResponse, ExchangeRateResponse>($request);
  }

  @override
  Future<Response<DailyPriceResponse>> getDailyPrice({String? currency}) {
    final Uri $url = Uri.parse('/api/v1/daily-price/');
    final Map<String, dynamic> $params = <String, dynamic>{
      'currency': currency
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<DailyPriceResponse, DailyPriceResponse>($request);
  }

  @override
  Future<Response<List<DailyPriceResponse>>> getLastDayPrices(
      {String? currency}) {
    final Uri $url = Uri.parse('/api/v1/prices/last-day/');
    final Map<String, dynamic> $params = <String, dynamic>{
      'currency': currency
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<List<DailyPriceResponse>, DailyPriceResponse>($request);
  }

  @override
  Future<Response<HealthResponse>> healthCheck() {
    final Uri $url = Uri.parse('/api/v1/health/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<HealthResponse, HealthResponse>($request);
  }

  @override
  Future<Response<CardResponse>> createCard(CardCreationRequest? request) {
    final Uri $url = Uri.parse('/api/v1/moon/card/');
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<CardResponse, CardResponse>($request);
  }

  @override
  Future<Response<CardResponse>> getCard(String cardId) {
    final Uri $url = Uri.parse('/api/v1/moon/card/${cardId}/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<CardResponse, CardResponse>($request);
  }

  @override
  Future<Response<CardListResponse>> getCards() {
    final Uri $url = Uri.parse('/api/v1/moon/cards/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<CardListResponse, CardListResponse>($request);
  }

  @override
  Future<Response<CardResponse>> updateCardSettings(
    String cardId,
    CardCreationRequest request,
  ) {
    final Uri $url = Uri.parse('/api/v1/moon/card/${cardId}/settings');
    final $body = request;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<CardResponse, CardResponse>($request);
  }

  @override
  Future<Response<AddBalanceResponse>> addCardBalance(
    String cardId,
    AmountRequest request,
  ) {
    final Uri $url = Uri.parse('/api/v1/moon/card/${cardId}/add-balance');
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<AddBalanceResponse, AddBalanceResponse>($request);
  }

  @override
  Future<Response<CardEventsResponse>> getCardEvents({
    required String cardId,
    int? perPage,
    int? page,
    bool? pending,
  }) {
    final Uri $url = Uri.parse('/api/v2/moon/card/${cardId}/events');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': perPage,
      'page': page,
      'pending': pending,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<CardEventsResponse, CardEventsResponse>($request);
  }

  @override
  Future<Response<CardVelocityResponse>> getCardVelocity(String cardId) {
    final Uri $url = Uri.parse('/api/v1/moon/card/${cardId}/velocity');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<CardVelocityResponse, CardVelocityResponse>($request);
  }

  @override
  Future<Response<GenerateInvoiceResponse>> generateInvoice(
      InvoiceRequest request) {
    final Uri $url = Uri.parse('/api/v1/moon/onchain/invoice');
    final $body = request;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client
        .send<GenerateInvoiceResponse, GenerateInvoiceResponse>($request);
  }

  @override
  Future<Response<TopupResponse>> updateTopup(String invoiceId) {
    final Uri $url = Uri.parse('/api/v1/moon/topup/${invoiceId}');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
    );
    return client.send<TopupResponse, TopupResponse>($request);
  }

  @override
  Future<Response<MoonRatesResponse>> getMoonRates() {
    final Uri $url = Uri.parse('/api/v1/moon/rates/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<MoonRatesResponse, MoonRatesResponse>($request);
  }

  @override
  Future<Response<MessageResponse>> getPublicMessage() {
    final Uri $url = Uri.parse('/api/v1/public/');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<MessageResponse, MessageResponse>($request);
  }
}
