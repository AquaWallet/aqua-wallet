import 'dart:async';
import 'dart:io';

import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
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

@ChopperApi(baseUrl: '/api/')
abstract class Jan3ApiService extends ChopperService {
  // Authentication
  @Post(path: 'v1/auth/login/')
  Future<Response<MessageResponse>> login(
    @Body() LoginRequest request,
  );

  @Post(path: 'v1/auth/verify/')
  Future<Response<AuthTokenResponse>> verify(
    @Body() VerifyRequest request,
  );

  @Post(path: 'v1/auth/user/email-reset/')
  Future<Response<AuthTokenResponse>> resetAccount();

  @Get(path: 'v1/auth/user/')
  Future<Response<ProfileResponse>> getUser();

  // Exchange Rates
  @Get(path: 'v1/exrates/')
  Future<Response<ExchangeRateResponse>> getExchangeRates();

  @Get(path: 'v1/daily-price/')
  Future<Response<DailyPriceResponse>> getDailyPrice({
    @Query('currency') String? currency,
  });

  @Get(path: 'v1/prices/last-day/')
  Future<Response<List<DailyPriceResponse>>> getLastDayPrices({
    @Query('currency') String? currency,
  });

  // Health Check
  @Get(path: 'v1/health/')
  Future<Response<HealthResponse>> healthCheck();

  // Card Management
  @Post(path: 'v1/moon/card/')
  Future<Response<CardResponse>> createCard(
    @Body() CardCreationRequest? request,
  );

  @Get(path: 'v1/moon/card/{card_id}/')
  Future<Response<CardResponse>> getCard(
    @Path('card_id') String cardId,
  );

  @Get(path: 'v1/moon/cards/')
  Future<Response<CardListResponse>> getCards();

  @Patch(path: 'v1/moon/card/{card_id}/settings')
  Future<Response<CardResponse>> updateCardSettings(
    @Path('card_id') String cardId,
    @Body() CardCreationRequest request,
  );

  @Post(path: 'v1/moon/card/{card_id}/add-balance')
  Future<Response<AddBalanceResponse>> addCardBalance(
    @Path('card_id') String cardId,
    @Body() AmountRequest request,
  );

  @Get(path: 'v2/moon/card/{card_id}/events')
  Future<Response<CardEventsResponse>> getCardEvents({
    @Path('card_id') required String cardId,
    @Query('limit') int? perPage,
    @Query('page') int? page,
    @Query('pending') bool? pending,
  });

  @Get(path: 'v1/moon/card/{card_id}/velocity')
  Future<Response<CardVelocityResponse>> getCardVelocity(
    @Path('card_id') String cardId,
  );

  // Moon On-chain Operations
  @Post(path: 'v1/moon/onchain/invoice')
  Future<Response<GenerateInvoiceResponse>> generateInvoice(
    @Body() InvoiceRequest request,
  );

  @Patch(path: 'v1/moon/topup/{invoice_id}')
  Future<Response<TopupResponse>> updateTopup(
    @Path('invoice_id') String invoiceId,
  );

  // Moon Rates
  @Get(path: 'v1/moon/rates/')
  Future<Response<MoonRatesResponse>> getMoonRates();

  // Public Endpoint
  @Get(path: 'v1/public/')
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
        TopupResponse: TopupResponse.fromJson,
        MoonRatesResponse: MoonRatesResponse.fromJson,
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
    } else if (response.statusCode == 403) {
      throw const RegionRestrictionException();
    }
    return response;
  }
}

class RegionRestrictionException implements ExceptionLocalized {
  const RegionRestrictionException();

  @override
  String toLocalizedString(BuildContext context) => context.loc.commonRegionBan;
}
