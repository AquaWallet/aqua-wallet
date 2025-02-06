import 'package:aqua/data/provider/secure_storage/auth_token_storage.dart';
import 'package:aqua/features/shared/providers/dio_interceptor.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:dio/dio.dart';

import 'btc_direct.dart';

final _logger = CustomLogger(FeatureFlag.btcDirect);

class BTCDirectAuthService implements AuthService {
  static const _tokenValidityDuration = Duration(hours: 1);

  final AuthTokenStorage _tokenStorage;
  final Dio _authDio;
  final EnvConfig _config;
  String? _authToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  bool _isAuthenticating = false;
  bool _isRefreshing = false;

  BTCDirectAuthService({
    required AuthTokenStorage tokenStorage,
    required Dio authDio,
    required EnvConfig config,
  })  : _tokenStorage = tokenStorage,
        _authDio = authDio,
        _config = config {
    _authDio.options.baseUrl = config.apiUrl;
    _authDio.options.connectTimeout = const Duration(seconds: 30);
    _authDio.options.receiveTimeout = const Duration(seconds: 30);
    _initializeTokens();
  }

  Future<void> _initializeTokens() async {
    final tokens =
        await _tokenStorage.getServiceTokens(AuthTokenService.btcDirect);
    if (tokens.error != null && !tokens.error!.expected) {
      _logger.error('Failed to load BTC Direct auth tokens: ${tokens.error}');
      return;
    }

    _authToken = tokens.token;
    _refreshToken = tokens.refreshToken;
    _tokenExpiry = tokens.expiry;

    if (_authToken != null) {
      _logger.debug('BTC Direct tokens loaded from storage');
    } else {
      _logger.debug('No stored BTC Direct tokens found');
    }
  }

  @override
  bool hasValidToken() {
    if (_authToken == null || _tokenExpiry == null) {
      _logger.debug('BTC Direct token not available');
      return false;
    }

    final isValid =
        _tokenExpiry!.isAfter(DateTime.now().add(const Duration(minutes: 5)));
    if (!isValid) {
      _logger.debug('BTC Direct token expired or expiring soon');
    }

    return isValid;
  }

  Future<void> _refreshAuthToken() async {
    if (_isRefreshing) {
      _logger.debug('Token refresh already in progress, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    try {
      _isRefreshing = true;
      _logger.debug('Refreshing auth token');

      if (_refreshToken == null) {
        _clearTokens();
        throw BTCDirectException(BTCDirectErrorCode.missingAuthToken);
      }

      final response = await _authDio.post(
        '/api/v1/refresh',
        data: {'refresh_token': _refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      _authToken = authResponse.token;
      _refreshToken = authResponse.refreshToken;
      _tokenExpiry = DateTime.now().add(_tokenValidityDuration);

      final error = await _tokenStorage.saveServiceTokens(
        service: AuthTokenService.btcDirect,
        token: _authToken!,
        refreshToken: _refreshToken!,
        expiry: _tokenExpiry!,
      );

      if (error != null) {
        _logger.error('Failed to save refreshed tokens: $error');
        throw BTCDirectException(BTCDirectErrorCode.internalError);
      }

      _logger.debug('Token refresh successful');
    } on BTCDirectException {
      _clearTokens();
      rethrow;
    } on DioException catch (e) {
      _logger.error('Token refresh failed: $e');
      _clearTokens();
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw BTCDirectException(BTCDirectErrorCode.timeoutError);
      }
      throw BTCDirectException(BTCDirectErrorCode.expiredAuthToken);
    } catch (e) {
      _logger.error('Token refresh failed with unexpected error: $e');
      _clearTokens();
      throw BTCDirectException(BTCDirectErrorCode.unknown);
    } finally {
      _isRefreshing = false;
    }
  }

  void _clearTokens() {
    _authToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }

  @override
  Future<void> authenticate() async {
    if (_isAuthenticating) {
      _logger.debug('Authentication already in progress, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (hasValidToken()) return;
      throw BTCDirectException(BTCDirectErrorCode.authenticationFailed);
    }

    if (_refreshToken != null && !_isRefreshing) {
      try {
        await _refreshAuthToken();
        return;
      } catch (e) {
        _logger.debug('Token refresh failed, attempting full authentication');
      }
    }

    try {
      _isAuthenticating = true;
      _logger.debug('Starting authentication process');

      final response = await _authDio.post(
        '/api/v1/authenticate',
        data: {
          'username': _config.username,
          'password': _config.password,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      _authToken = authResponse.token;
      _refreshToken = authResponse.refreshToken;
      _tokenExpiry = DateTime.now().add(_tokenValidityDuration);

      final error = await _tokenStorage.saveServiceTokens(
        service: AuthTokenService.btcDirect,
        token: _authToken!,
        refreshToken: _refreshToken!,
        expiry: _tokenExpiry!,
      );

      if (error != null) {
        _logger.error('Failed to save auth tokens: $error');
      }

      _logger.debug('Authentication successful');
    } catch (e) {
      _logger.error('Authentication error: $e');
      throw BTCDirectException(BTCDirectErrorCode.authenticationFailed);
    } finally {
      _isAuthenticating = false;
    }
  }

  @override
  bool shouldInterceptRequest(RequestOptions options) =>
      !options.path.contains('/api/v1/authenticate') &&
      !options.path.contains('/api/v1/refresh');

  @override
  bool isAuthError(DioException error) {
    final statusCode = error.response?.statusCode;
    final errorCode = error.response?.data?['errors']?['ER801']?['code'];

    return statusCode == 401 || (statusCode == 400 && errorCode == 'ER801');
  }

  Map<String, String> get authHeaders => {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      };

  Future<void> logout() async {
    final error =
        await _tokenStorage.clearServiceTokens(AuthTokenService.btcDirect);
    if (error != null) {
      _logger.error('Failed to clear auth tokens: $error');
    }
    _authToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }
}

final btcDirectAuthServiceProvider = Provider<BTCDirectAuthService>((ref) {
  final dio = createDioInstance(
    enableCurlLogging: true,
    loggerFlag: FeatureFlag.btcDirect,
  );

  ref.onDispose(() {
    dio.close();
  });

  return BTCDirectAuthService(
    tokenStorage: ref.watch(authTokenStorageProvider),
    authDio: dio,
    config: ref.watch(btcDirectEnvConfigProvider),
  );
});
