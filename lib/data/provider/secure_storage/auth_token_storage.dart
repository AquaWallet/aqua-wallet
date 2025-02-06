import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:aqua/features/shared/shared.dart';

enum AuthTokenService {
  btcDirect('btc_direct');

  final String value;
  const AuthTokenService(this.value);
}

class AuthTokenKeys {
  static const _prefix = 'auth_tokens';

  // Token types
  static const tokenType = 'token';
  static const refreshType = 'refresh';
  static const expiryType = 'expiry';

  // Service-specific keys
  static String btcDirectToken =
      createAuthKey(AuthTokenService.btcDirect, tokenType);
  static String btcDirectRefresh =
      createAuthKey(AuthTokenService.btcDirect, refreshType);
  static String btcDirectExpiry =
      createAuthKey(AuthTokenService.btcDirect, expiryType);

  static String createAuthKey(AuthTokenService service, String type) =>
      '$_prefix.${service.value}.$type';
}

class AuthTokenStorage {
  final IStorage _storage;

  const AuthTokenStorage(this._storage);

  Future<StorageError?> saveServiceTokens({
    required AuthTokenService service,
    required String token,
    required String refreshToken,
    required DateTime expiry,
  }) async {
    final results = await Future.wait([
      _storage.save(
        key: AuthTokenKeys.createAuthKey(service, AuthTokenKeys.tokenType),
        value: token,
      ),
      _storage.save(
        key: AuthTokenKeys.createAuthKey(service, AuthTokenKeys.refreshType),
        value: refreshToken,
      ),
      _storage.save(
        key: AuthTokenKeys.createAuthKey(service, AuthTokenKeys.expiryType),
        value: expiry.toIso8601String(),
      ),
    ]);

    return results.firstWhere((error) => error != null, orElse: () => null);
  }

  Future<
      ({
        String? token,
        String? refreshToken,
        DateTime? expiry,
        StorageError? error,
      })> getServiceTokens(AuthTokenService service) async {
    final results = await Future.wait([
      _storage
          .get(AuthTokenKeys.createAuthKey(service, AuthTokenKeys.tokenType)),
      _storage
          .get(AuthTokenKeys.createAuthKey(service, AuthTokenKeys.refreshType)),
      _storage
          .get(AuthTokenKeys.createAuthKey(service, AuthTokenKeys.expiryType)),
    ]);

    final error = results
        .map((r) => r.$2)
        .firstWhere((error) => error != null, orElse: () => null);
    if (error != null) {
      return (token: null, refreshToken: null, expiry: null, error: error);
    }

    return (
      token: results[0].$1,
      refreshToken: results[1].$1,
      expiry: results[2].$1 != null ? DateTime.parse(results[2].$1!) : null,
      error: null,
    );
  }

  Future<StorageError?> clearServiceTokens(AuthTokenService service) async {
    final results = await Future.wait([
      _storage.delete(
          AuthTokenKeys.createAuthKey(service, AuthTokenKeys.tokenType)),
      _storage.delete(
          AuthTokenKeys.createAuthKey(service, AuthTokenKeys.refreshType)),
      _storage.delete(
          AuthTokenKeys.createAuthKey(service, AuthTokenKeys.expiryType)),
    ]);

    return results.firstWhere((error) => error != null, orElse: () => null);
  }
}

final authTokenStorageProvider = Provider<AuthTokenStorage>(
  (ref) => AuthTokenStorage(ref.watch(secureStorageProvider)),
);
