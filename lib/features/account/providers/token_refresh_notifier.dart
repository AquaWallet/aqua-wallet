import 'dart:convert';

import 'package:coin_cz/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:coin_cz/features/account/models/api_models.dart';
import 'package:coin_cz/features/account/providers/jan3_auth_token_provider.dart';
import 'package:coin_cz/features/account/services/jan3_api_token_refresh.dart';
import 'package:coin_cz/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final tokenRefreshNotifierProvider =
    AsyncNotifierProvider<TokenRefreshNotifier, void>(
        () => TokenRefreshNotifier());

final logger = CustomLogger(FeatureFlag.jan3AuthToken);

class TokenRefreshNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> refreshToken() async {
    if (state.isLoading) {
      logger.debug(
          '[TokenRefreshNotifier] refreshToken called but already loading, waiting for completion');
      // Wait for the existing refresh operation to complete
      await future;
      return;
    }

    state = await AsyncValue.guard(() async {
      final api = await ref.read(jan3RequestTokenApiProvider.future);
      final storage = ref.read(secureStorageProvider);

      logger.debug('[TokenRefreshNotifier] refreshToken called');

      final (token, error) = await storage.get(Jan3AuthTokenManager.tokenKey);
      if (error != null) {
        logger.debug('[TokenRefreshNotifier] No token found');
        return;
      }

      final oldToken = AuthTokenResponse.fromJson(jsonDecode(token!));

      final response = await api.refresh(
        RefreshTokenRequest(refresh: oldToken.refresh),
      );

      if (response.isSuccessful && response.body != null) {
        final newToken = AuthTokenResponse(
          access: response.body!.access,
          refresh: oldToken.refresh,
        );

        await storage.delete(Jan3AuthTokenManager.tokenKey);
        await storage.save(
          key: Jan3AuthTokenManager.tokenKey,
          value: jsonEncode(newToken.toJson()),
        );

        logger.debug('[TokenRefreshNotifier] Token refreshed');
      } else {
        logger.warning('[TokenRefreshNotifier] Token refresh failed');
        await storage.delete(Jan3AuthTokenManager.tokenKey);
        throw Exception('Token refresh failed');
      }
    });
  }
}
