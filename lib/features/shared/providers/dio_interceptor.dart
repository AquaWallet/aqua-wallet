import 'package:dio/dio.dart';
import 'package:coin_cz/logger.dart';

final _logger = CustomLogger(FeatureFlag.network);

abstract class AuthService {
  Future<void> authenticate();
  bool shouldInterceptRequest(RequestOptions options);
  bool isAuthError(DioException error);
  bool hasValidToken();
}

class AuthInterceptor extends QueuedInterceptor {
  final AuthService _authService;
  final Dio _dio;
  bool _isRefreshing = false;

  AuthInterceptor(this._authService, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_authService.shouldInterceptRequest(options)) {
      return handler.next(options);
    }

    try {
      if (!_isRefreshing && !_authService.hasValidToken()) {
        _logger.debug(
            'No valid token, authenticating before request to: ${options.path}');
        await _authService.authenticate();
      }
      handler.next(options);
    } catch (e) {
      _logger.error('Authentication failed: $e');
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Authentication failed',
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_authService.isAuthError(err) && !_isRefreshing) {
      _isRefreshing = true;
      try {
        _logger.debug('Auth error, attempting to refresh');
        await _authService.authenticate();
        _isRefreshing = false;

        // Retry the original request using the Dio instance
        final response = await _dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        _logger.error('Auth refresh failed: $e');
      } finally {
        _isRefreshing = false;
      }
    }
    handler.reject(err);
  }
}
