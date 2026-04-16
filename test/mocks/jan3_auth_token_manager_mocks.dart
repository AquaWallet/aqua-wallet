import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:aqua/features/account/models/models.dart';
import 'package:aqua/features/account/providers/jan3_auth_token_provider.dart';
import 'package:aqua/features/account/providers/token_refresh_notifier.dart';
import 'package:chopper/chopper.dart';

/// Fake [Jan3AuthTokenManager] with constructor-injected behavior.
/// Avoids per-test `when()` stubs for the common token-manager operations.
class FakeJan3AuthTokenManager implements Jan3AuthTokenManager {
  FakeJan3AuthTokenManager({
    this.accessToken,
    this.storedToken,
    IStorage? storage,
    String walletId = 'test-wallet',
  })  : _storage = storage ?? _NoOpStorage(),
        _walletId = walletId;

  final String? accessToken;
  final AuthTokenResponse? storedToken;
  final IStorage _storage;
  final String _walletId;

  @override
  String get walletId => _walletId;

  @override
  IStorage get storage => _storage;

  @override
  String get tokenKey => Jan3AuthTokenManager.tokenKeyForWallet(_walletId);

  @override
  TokenRefreshNotifier get tokenRefreshNotifier => throw UnimplementedError();

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<AuthTokenResponse?> readTokenWithoutRefresh() async => storedToken;

  @override
  Future<void> saveToken(Response<AuthTokenResponse> response) async {}

  @override
  Future<void> deleteToken() async {}

  @override
  Future<void> refreshToken() async {}
}

/// No-op [IStorage] used when storage interactions are not under test.
class _NoOpStorage implements IStorage {
  @override
  Future<(String?, StorageError?)> get(String key) async => (null, null);

  @override
  Future<StorageError?> save({
    required String key,
    required String value,
  }) async =>
      null;

  @override
  Future<StorageError?> delete(String key) async => null;

  @override
  Future<(Map<String, String>?, StorageError?)> getAll() async => (null, null);

  @override
  Future<StorageError?> deleteAll() async => null;
}

/// [IStorage] that records save/delete calls, for asserting side-effects.
class SpyStorage extends _NoOpStorage {
  final List<String> deletedKeys = [];
  final Map<String, String> savedEntries = {};

  @override
  Future<StorageError?> delete(String key) async {
    deletedKeys.add(key);
    return null;
  }

  @override
  Future<StorageError?> save({
    required String key,
    required String value,
  }) async {
    savedEntries[key] = value;
    return null;
  }
}
