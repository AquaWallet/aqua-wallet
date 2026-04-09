import 'dart:async';
import 'dart:convert';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/account/models/models.dart';
import 'package:aqua/features/account/providers/token_refresh_notifier.dart';
import 'package:aqua/logger.dart';
import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jan3AuthTokenManagerProvider =
    Provider.family<Jan3AuthTokenManager, String>((ref, walletId) {
  final tokenRefreshNotifier =
      ref.watch(tokenRefreshNotifierProvider(walletId).notifier);
  final storage = ref.read(secureStorageProvider);
  return Jan3AuthTokenManager(
    walletId: walletId,
    tokenRefreshNotifier: tokenRefreshNotifier,
    storage: storage,
  );
});

class Jan3AuthTokenManager {
  Jan3AuthTokenManager({
    required this.walletId,
    required this.tokenRefreshNotifier,
    required this.storage,
  });

  final String walletId;
  final TokenRefreshNotifier tokenRefreshNotifier;
  final IStorage storage;
  final _logger = CustomLogger(FeatureFlag.jan3AuthToken);

  /// Per-wallet storage key.
  String get tokenKey => tokenKeyForWallet(walletId);

  /// Computes the storage key for any wallet ID.
  static String tokenKeyForWallet(String walletId) =>
      'jan3_auth_token_$walletId';

  /// Legacy key used before per-wallet tokens were introduced.
  @Deprecated(
      'Used before when only single wallet was supported. Left only for migration purpose.')
  static const legacyTokenKey = 'jan3_auth_token';

  Future<void> refreshToken() async {
    return await tokenRefreshNotifier.refreshToken();
  }

  Future<void> saveToken(Response<AuthTokenResponse> response) async {
    assert(response.body != null, 'Response body is null');
    final access = response.body!.access;

    _logger.debug(
        '[Jan3AuthTokenManager] saveToken called with access: ${access.substring(0, 10)}...');
    await storage.delete(tokenKey);
    await storage.save(
      key: tokenKey,
      value: jsonEncode(response.body!.toJson()),
    );
    _logger.debug('[Jan3AuthTokenManager] Token saved');
  }

  Future<void> deleteToken() async {
    _logger.debug('[Jan3AuthTokenManager] deleteToken called');
    await storage.delete(tokenKey);
    _logger.debug('[Jan3AuthTokenManager] Token deleted');
  }

  Future<AuthTokenResponse?> readTokenWithoutRefresh() async {
    _logger.debug('[Jan3AuthTokenManager] _readTokenWithoutRefresh called');
    final (token, error) = await storage.get(tokenKey);

    if (error == null && token != null) {
      _logger.debug('[Jan3AuthTokenManager] Token found in storage');
      return AuthTokenResponse.fromJson(jsonDecode(token));
    } else {
      _logger.debug('[Jan3AuthTokenManager] No token found in storage');
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    _logger.debug('[Jan3AuthTokenManager] getAccessToken called');
    AuthTokenResponse? tokenResponse = await readTokenWithoutRefresh();

    if (tokenResponse == null) {
      _logger.debug(
          '[Jan3AuthTokenManager] No token found, cannot get access token');
      return null;
    }

    if (tokenResponse.access.isExpiredOrAboutTo) {
      _logger.debug(
          '[Jan3AuthTokenManager] Access token expired or about to expire, refreshing...');
      try {
        // Wait for the refresh operation to complete, even if it's already in progress
        await tokenRefreshNotifier.refreshToken();
        // Re-read the token after refresh completes
        tokenResponse = await readTokenWithoutRefresh();
      } catch (e) {
        _logger.error('[Jan3AuthTokenManager] Error during token refresh: $e');
        return null;
      }
    } else {
      _logger.debug('[Jan3AuthTokenManager] Access token is valid');
    }

    return tokenResponse?.access;
  }
}
