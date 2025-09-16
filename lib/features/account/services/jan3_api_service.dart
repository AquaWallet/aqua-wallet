import 'dart:async';
import 'dart:io';

import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/account/account.dart';
import 'package:coin_cz/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:chopper/chopper.dart';
import 'package:http/io_client.dart' as http;

part 'jan3_api_service.chopper.dart';

final jan3ApiServiceProvider =
    FutureProvider.autoDispose<Jan3ApiService>((ref) async {
  final onUnauthorized = ref.read(jan3AuthProvider.notifier).onUnauthorized;
  final tokenManager = ref.watch(jan3AuthTokenManagerProvider);
  final debitCardStagingEnabled =
      ref.read(featureFlagsProvider.select((p) => p.debitCardStagingEnabled));
  return Jan3ApiService.create(
      tokenManager, onUnauthorized, debitCardStagingEnabled);
});

@ChopperApi(baseUrl: '/api/v1/')
abstract class Jan3ApiService extends ChopperService {
  // Authentication
  @Post(path: 'auth/login/')
  Future<Response<MessageResponse>> login(
    @Body() LoginRequest request,
  );

  @Post(path: 'auth/verify/')
  Future<Response<AuthTokenResponse>> verify(
    @Body() VerifyRequest request,
  );

  @Post(path: 'auth/user/email-reset/')
  Future<Response<AuthTokenResponse>> resetAccount();

  @Get(path: 'auth/user/')
  Future<Response<ProfileResponse>> getUser();

  // Exchange Rates
  @Get(path: 'exrates/')
  Future<Response<ExchangeRateResponse>> getExchangeRates();

  @Get(path: 'daily-price/')
  Future<Response<DailyPriceResponse>> getDailyPrice();

  // Health Check
  @Get(path: 'health/')
  Future<Response<HealthResponse>> healthCheck();

  // Card Management
  @Post(path: 'moon/card/')
  Future<Response<CardResponse>> createCard(
    @Body() CardCreationRequest? request,
  );

  @Get(path: 'moon/card/{card_id}/')
  Future<Response<CardResponse>> getCard(
    @Path('card_id') String cardId,
  );

  @Get(path: 'moon/cards/')
  Future<Response<CardListResponse>> getCards();

  @Patch(path: 'moon/card/{card_id}/settings')
  Future<Response<CardResponse>> updateCardSettings(
    @Path('card_id') String cardId,
    @Body() CardCreationRequest request,
  );

  @Post(path: 'moon/card/{card_id}/add-balance')
  Future<Response<AddBalanceResponse>> addCardBalance(
    @Path('card_id') String cardId,
    @Body() AmountRequest request,
  );

  @Get(path: 'moon/card/{card_id}/events')
  Future<Response<CardEventsResponse>> getCardEvents(
    @Path('card_id') String cardId,
  );

  @Get(path: 'moon/card/{card_id}/velocity')
  Future<Response<CardVelocityResponse>> getCardVelocity(
    @Path('card_id') String cardId,
  );

  // Moon On-chain Operations
  @Post(path: 'moon/onchain/invoice')
  Future<Response<GenerateInvoiceResponse>> generateInvoice(
    @Body() InvoiceRequest request,
  );

  // Public Endpoint
  @Get(path: 'public/')
  Future<Response<MessageResponse>> getPublicMessage();

  static Jan3ApiService create(
    Jan3AuthTokenManager tokenManager,
    VoidCallback onUnauthorized,
    bool debitCardStagingEnabled,
  ) {
    final client = ChopperClient(
      client: http.IOClient(
        HttpClient()..connectionTimeout = const Duration(seconds: 10),
      ),
      baseUrl: Uri.parse(debitCardStagingEnabled
          ? aquaAnkaraStagingApiUrl
          : aquaAnkaraProdApiUrl),
      services: [_$Jan3ApiService()],
      interceptors: [
        HttpLoggingInterceptor(),
        Jan3ApiAuthInterceptor(tokenManager),
        Jan3ApiResponseInterceptor(onUnauthorized),
      ],
      errorConverter: const JsonConverter(),
      converter: const JsonToTypeConverter({
        MessageResponse: MessageResponse.fromJson,
        AuthTokenResponse: AuthTokenResponse.fromJson,
        ProfileResponse: ProfileResponse.fromJson,
        ExchangeRateResponse: ExchangeRateResponse.fromJson,
        CardResponse: CardResponse.fromJson,
        CardListResponse: CardListResponse.fromJson,
        AddBalanceResponse: AddBalanceResponse.fromJson,
        GenerateInvoiceResponse: GenerateInvoiceResponse.fromJson,
        DailyPriceResponse: DailyPriceResponse.fromJson,
        HealthResponse: HealthResponse.fromJson,
        AccessTokenResponse: AccessTokenResponse.fromJson,
        CardEventsResponse: CardEventsResponse.fromJson,
        CardVelocityResponse: CardVelocityResponse.fromJson,
        CardCreationRequest: CardCreationRequest.fromJson,
      }),
    );
    return _$Jan3ApiService(client);
  }
}

class Jan3ApiAuthInterceptor implements RequestInterceptor {
  Jan3ApiAuthInterceptor(
    this.tokenManager,
  );

  final Jan3AuthTokenManager tokenManager;

  @override
  FutureOr<Request> onRequest(Request request) async {
    final token = await tokenManager.getAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return request;
  }
}

class Jan3ApiResponseInterceptor implements ResponseInterceptor {
  Jan3ApiResponseInterceptor(this.onUnauthorized);

  final VoidCallback onUnauthorized;

  @override
  FutureOr<Response> onResponse(Response response) {
    if (response.statusCode == 401) {
      onUnauthorized();
    }
    return response;
  }
}
