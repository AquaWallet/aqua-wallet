import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/data/provider/secure_storage/auth_token_storage.dart';
import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {
  final _options = BaseOptions(
    baseUrl: btcDirectSandboxUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  );

  @override
  BaseOptions get options => _options;
}

class MockAuthTokenStorage extends Mock implements AuthTokenStorage {}

class MockResponse extends Mock implements Response {}

class MockRef extends Mock implements Ref {}

void main() {
  setUpAll(() {
    registerFallbackValue(AuthTokenService.btcDirect);
    registerFallbackValue(Options());
    registerFallbackValue(
      (
        token: null,
        refreshToken: null,
        expiry: null,
        error: null,
      ),
    );
  });

  group('BTCDirectAuthService', () {
    late MockDio mockDio;
    late MockAuthTokenStorage mockStorage;
    late BTCDirectAuthService service;
    late EnvConfig mockConfig;

    setUp(() {
      mockDio = MockDio();
      mockStorage = MockAuthTokenStorage();
      mockConfig = const EnvConfig(
        apiUrl: btcDirectSandboxUrl,
        apiKey: 'test_api_key',
        username: 'test_username',
        password: 'test_password',
        secret: 'test_secret',
      );

      when(() => mockStorage.getServiceTokens(any())).thenAnswer(
        (_) async => (
          token: null,
          refreshToken: null,
          expiry: null,
          error: null,
        ),
      );

      when(() => mockDio.interceptors).thenReturn(Interceptors());

      service = BTCDirectAuthService(
        tokenStorage: mockStorage,
        authDio: mockDio,
        config: mockConfig,
      );
    });

    group('initialization', () {
      test('loads tokens from storage on creation', () async {
        clearInteractions(mockStorage);

        when(() => mockStorage.getServiceTokens(AuthTokenService.btcDirect))
            .thenAnswer(
          (_) async => (
            token: 'stored_token',
            refreshToken: 'stored_refresh',
            expiry: null,
            error: null,
          ),
        );

        service = BTCDirectAuthService(
          tokenStorage: mockStorage,
          authDio: mockDio,
          config: mockConfig,
        );
        await Future.delayed(Duration.zero);

        verify(() => mockStorage.getServiceTokens(AuthTokenService.btcDirect))
            .called(1);
      });

      test('handles storage error gracefully', () async {
        when(() => mockStorage.getServiceTokens(AuthTokenService.btcDirect))
            .thenAnswer(
          (_) async => (
            token: null,
            refreshToken: null,
            expiry: null,
            error: StorageError('Test error', expected: false),
          ),
        );

        service = BTCDirectAuthService(
          tokenStorage: mockStorage,
          authDio: mockDio,
          config: mockConfig,
        );
        await Future.delayed(Duration.zero);

        expect(service.hasValidToken(), isFalse);
      });
    });

    group('hasValidToken', () {
      test('returns false when token is expired', () async {
        when(() => mockStorage.getServiceTokens(AuthTokenService.btcDirect))
            .thenAnswer(
          (_) async => (
            token: 'test_token',
            refreshToken: 'test_refresh',
            expiry: DateTime.now().subtract(const Duration(hours: 2)),
            error: null,
          ),
        );

        service = BTCDirectAuthService(
          tokenStorage: mockStorage,
          authDio: mockDio,
          config: mockConfig,
        );
        await Future.delayed(Duration.zero);

        expect(service.hasValidToken(), isFalse);
      });

      test('returns false when token expires in less than 5 minutes', () async {
        when(() => mockStorage.getServiceTokens(AuthTokenService.btcDirect))
            .thenAnswer(
          (_) async => (
            token: 'test_token',
            refreshToken: 'test_refresh',
            expiry: DateTime.now().add(const Duration(minutes: 4)),
            error: null,
          ),
        );

        service = BTCDirectAuthService(
          tokenStorage: mockStorage,
          authDio: mockDio,
          config: mockConfig,
        );
        await Future.delayed(Duration.zero);

        expect(service.hasValidToken(), isFalse);
      });

      test('returns true for valid non-expired token', () async {
        when(() => mockStorage.getServiceTokens(AuthTokenService.btcDirect))
            .thenAnswer(
          (_) async => (
            token: 'test_token',
            refreshToken: 'test_refresh',
            expiry: DateTime.now().add(const Duration(hours: 1)),
            error: null,
          ),
        );

        service = BTCDirectAuthService(
          tokenStorage: mockStorage,
          authDio: mockDio,
          config: mockConfig,
        );
        await Future.delayed(Duration.zero);

        expect(service.hasValidToken(), isTrue);
      });
    });

    group('authenticate', () {
      test('performs full authentication when no refresh token exists',
          () async {
        clearInteractions(mockStorage);

        final mockResponse = MockResponse();
        when(() => mockResponse.data).thenReturn({
          'token': 'new_token',
          'refreshToken': 'new_refresh',
        });

        when(() => mockDio.post(
              '/api/v1/authenticate',
              data: {
                'username': 'test_username',
                'password': 'test_password',
              },
              options: any(named: 'options'),
            )).thenAnswer((_) => Future.value(mockResponse));

        when(() => mockStorage.saveServiceTokens(
              service: any(named: 'service'),
              token: any(named: 'token'),
              refreshToken: any(named: 'refreshToken'),
              expiry: any(named: 'expiry'),
            )).thenAnswer((_) => Future<StorageError?>.value(null));

        service = BTCDirectAuthService(
          tokenStorage: mockStorage,
          authDio: mockDio,
          config: mockConfig,
        );
        await service.authenticate();

        verify(() => mockStorage.saveServiceTokens(
              service: AuthTokenService.btcDirect,
              token: 'new_token',
              refreshToken: 'new_refresh',
              expiry: any(named: 'expiry'),
            )).called(1);
      });

      test('attempts token refresh before full authentication', () async {
        clearInteractions(mockStorage);

        final mockResponse = MockResponse();
        when(() => mockResponse.data).thenReturn({
          'token': 'refreshed_token',
          'refreshToken': 'refreshed_refresh', // Changed from refresh_token
        });

        when(() => mockDio.post(
              '/api/v1/refresh',
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => mockResponse);

        when(() => mockStorage.saveServiceTokens(
              service: AuthTokenService.btcDirect,
              token: any(named: 'token'),
              refreshToken: any(named: 'refreshToken'),
              expiry: any(named: 'expiry'),
            )).thenAnswer((_) async => null);

        // Set up initial tokens
        when(() => mockStorage.getServiceTokens(any())).thenAnswer(
          (_) async => (
            token: 'old_token',
            refreshToken: 'old_refresh',
            expiry: DateTime.now().subtract(const Duration(minutes: 10)),
            error: null,
          ),
        );

        service = BTCDirectAuthService(
          tokenStorage: mockStorage,
          authDio: mockDio,
          config: mockConfig,
        );
        await Future.delayed(Duration.zero);
        await service.authenticate();

        verify(() => mockStorage.saveServiceTokens(
              service: AuthTokenService.btcDirect,
              token: 'refreshed_token',
              refreshToken: 'refreshed_refresh',
              expiry: any(named: 'expiry'),
            )).called(1);
      });
    });

    group('logout', () {
      test('clears tokens from storage and memory', () async {
        when(() => mockStorage.clearServiceTokens(AuthTokenService.btcDirect))
            .thenAnswer((_) async => null);

        await service.logout();

        verify(() => mockStorage.clearServiceTokens(AuthTokenService.btcDirect))
            .called(1);
        expect(service.hasValidToken(), isFalse);
      });
    });

    group('interceptor behavior', () {
      test('shouldInterceptRequest returns correct values', () {
        expect(
          service.shouldInterceptRequest(
            RequestOptions(path: '/api/v1/some/endpoint'),
          ),
          isTrue,
        );

        expect(
          service.shouldInterceptRequest(
            RequestOptions(path: '/api/v1/authenticate'),
          ),
          isFalse,
        );

        expect(
          service.shouldInterceptRequest(
            RequestOptions(path: '/api/v1/refresh'),
          ),
          isFalse,
        );
      });

      test('isAuthError correctly identifies auth errors', () {
        final authError = DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final nonAuthError = DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        expect(service.isAuthError(authError), isTrue);
        expect(service.isAuthError(nonAuthError), isFalse);
      });
    });
  });
}
