import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/marketplace/providers/on_ramp_setup_provider.dart';
import 'package:aqua/features/private_integrations/btc_direct/btc_direct_providers.dart';
import 'package:aqua/features/shared/providers/dio_interceptor.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:dio/dio.dart';
import 'package:aqua/config/constants/constants.dart' as constants;

import 'btc_direct.dart';

final _logger = CustomLogger(FeatureFlag.btcDirect);

class BTCDirectApiService {
  static const _timeoutDuration = Duration(seconds: 30);

  final Dio _dio;
  final BTCDirectAuthService _authService;
  final EnvConfig _config;

  static final _defaultOptions = Options(
    sendTimeout: _timeoutDuration,
    receiveTimeout: _timeoutDuration,
  );

  BTCDirectApiService({
    required Dio dio,
    required BTCDirectAuthService authService,
    required EnvConfig config,
  })  : _dio = dio,
        _authService = authService,
        _config = config {
    _dio.options.baseUrl = _config.apiUrl;
    _dio.options.connectTimeout = _timeoutDuration;
    _dio.options.receiveTimeout = _timeoutDuration;
    _dio.interceptors.add(AuthInterceptor(_authService, _dio));
  }

  Never _handleError(DioException e, String context) {
    _logger.error('$context: ${e.message}', e, StackTrace.current);

    // Handle specific auth errors
    if (e.response?.statusCode == 401) {
      throw BTCDirectException(BTCDirectErrorCode.authenticationFailed);
    }

    if (e.response?.data != null) {
      throw BTCDirectException.fromResponse(e.response!.data);
    }

    // Handle network errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw BTCDirectException(BTCDirectErrorCode.networkError);
    }

    throw BTCDirectException(BTCDirectErrorCode.unknown);
  }

  Future<BTCPriceResponse> getBTCPrice({double? fee}) async {
    try {
      _logger.debug('Fetching BTCDirect BTC price');
      var url = '/api/v1/prices';

      if (fee != null) {
        url += '?fee=$fee';
      }

      // Ensure we're authenticated before making the request
      if (!_authService.hasValidToken()) {
        await _authService.authenticate();
      }

      final response = await _dio.get(
        url,
        options: _defaultOptions.copyWith(headers: _authService.authHeaders),
      );

      final priceResponse = BTCPriceResponse.fromJson(response.data);
      _logger.debug('BTC price fetched successfully');
      return priceResponse;
    } on DioException catch (e) {
      _handleError(e, 'BTC price fetch error');
    }
  }

  Future<String> createCheckoutUrl(CheckoutRequest request) async {
    try {
      _logger.debug('Creating checkout URL');

      // Ensure we're authenticated before making the request
      if (!_authService.hasValidToken()) {
        await _authService.authenticate();
      }

      const url = '/api/v2/buy/checkout';
      final response = await _dio.post(
        url,
        data: request.toJson(),
        options: _defaultOptions.copyWith(headers: _authService.authHeaders),
      );

      final checkoutResponse = CheckoutResponse.fromJson(response.data);
      _logger.debug('Checkout URL created successfully');
      return checkoutResponse.checkoutUrl;
    } on DioException catch (e) {
      _handleError(e, 'Checkout URL creation error');
    }
  }

  Future<void> registerUser(UserRegistrationRequest request) async {
    try {
      if (!_authService.hasValidToken()) {
        await _authService.authenticate();
      }

      const url = '/api/v1/user/register-identifier';
      await _dio.post(
        url,
        data: request.toJson(),
        options: _defaultOptions.copyWith(headers: _authService.authHeaders),
      );
      _logger.debug('User registration successful');
    } on DioException catch (e) {
      _handleError(e, 'User registration error');
    }
  }

  Future<PaymentMethodsResponse> getPaymentMethods(
      {bool preferred = false}) async {
    try {
      _logger.debug('Fetching payment methods');
      final type = preferred ? 'preferred' : 'all';
      final url = '/api/v1/buy/payment-methods/$type';

      if (!_authService.hasValidToken()) {
        await _authService.authenticate();
      }

      final response = await _dio.get(
        url,
        options: _defaultOptions.copyWith(headers: _authService.authHeaders),
      );

      if (response.data == null) {
        throw BTCDirectException(BTCDirectErrorCode.unknown);
      }

      // Log supported countries
      final data = response.data as Map<String, dynamic>;
      if (data['countries'] != null) {
        final countries =
            (data['countries'] as Map<String, dynamic>).keys.toList();
        _logger.debug('Supported countries: $countries');
      }

      final methodsResponse = PaymentMethodsResponse.fromJson(response.data);
      _logger.debug('Payment methods fetched successfully');
      return methodsResponse;
    } on DioException catch (e) {
      _handleError(e, 'Payment methods fetch error');
    }
  }

  // Helper method to fetch supported countries
  Future<List<String>> getSupportedCountries() async {
    final response = await getPaymentMethods();
    final countries = response.countries.keys.toList();
    _logger.debug('Supported countries: $countries');
    return countries;
  }
}

final btcDirectApiServiceProvider =
    Provider.autoDispose<BTCDirectApiService>((ref) {
  final authService = ref.watch(btcDirectAuthServiceProvider);
  final config = ref.watch(btcDirectEnvConfigProvider);
  final dio = Dio();

  ref.onDispose(() {
    dio.close();
  });

  return BTCDirectApiService(
    dio: dio,
    authService: authService,
    config: config,
  );
});

class BTCDirectPriceFetcher implements OnRampPriceFetcher {
  final BTCDirectApiService _service;

  BTCDirectPriceFetcher(this._service);

  @override
  Future<String?> fetchPrice(OnRampIntegration integration, Ref ref) async {
    try {
      _logger.debug('Fetching BTC price for ${integration.name}');
      final priceResponse = await _service.getBTCPrice();
      final formatter = ref.read(currencyFormatProvider(0));
      final price = double.parse(priceResponse.buyPrice);
      final formattedPrice =
          "${integration.priceSymbol}${formatter.format(price)}";
      _logger.debug('Fetched price for ${integration.name}: $formattedPrice');
      return formattedPrice;
    } catch (e) {
      rethrow;
    }
  }
}

class BTCDirectIntegrationHandler implements OnRampIntegrationHandler {
  final BTCDirectApiService _btcDirectService;
  final BitcoinProvider _bitcoinProvider;
  final Future<String> Function() _getUserHashId;

  BTCDirectIntegrationHandler({
    required BTCDirectApiService btcDirectService,
    required BitcoinProvider bitcoinProvider,
    required Future<String> Function() getUserHashId,
  })  : _btcDirectService = btcDirectService,
        _bitcoinProvider = bitcoinProvider,
        _getUserHashId = getUserHashId;

  @override
  Future<String> getIntegrationUrl(OnRampIntegration integration) async {
    // Generate a unique identifier for the user
    final userIdentifier = await _getUserHashId();

    // Register the user
    await _btcDirectService.registerUser(
      UserRegistrationRequest(
        identifier: userIdentifier,
        returnUrl: constants.aquaWebsiteUrl,
      ),
    );

    // Get BTC receive address
    final receiveAddress = await _bitcoinProvider.getReceiveAddress();
    if (receiveAddress == null || receiveAddress.address == null) {
      throw Exception('Failed to get receive address');
    }

    // Create checkout URL
    final checkoutUrl = await _btcDirectService.createCheckoutUrl(
      CheckoutRequest(
        baseCurrency: 'BTC',
        quoteCurrency: 'EUR',
        walletAddress: receiveAddress.address!,
        returnUrl: constants.aquaWebsiteUrl,
      ),
    );

    return checkoutUrl;
  }
}
