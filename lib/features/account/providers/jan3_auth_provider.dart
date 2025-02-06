import 'dart:convert';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:flutter/foundation.dart';

final _logger = CustomLogger(FeatureFlag.jan3Account);

final jan3AuthProvider =
    AsyncNotifierProvider.autoDispose<Jan3AuthNotifier, Jan3AuthState>(
        Jan3AuthNotifier.new);

class Jan3AuthNotifier extends AutoDisposeAsyncNotifier<Jan3AuthState> {
  static const tokenKey = 'jan3_auth_token';

  Future<AuthTokenResponse?> get _tokenResponse => ref
      .read(secureStorageProvider)
      .get(tokenKey)
      .then((value) => value.$2 == null
          ? AuthTokenResponse.fromJson(jsonDecode(value.$1!))
          : null);

  @override
  Future<Jan3AuthState> build() async {
    final tokenResponse = await _tokenResponse;
    if (tokenResponse != null) {
      final api = await ref.read(jan3ApiServiceProvider.future);
      final response = await api.getUser();
      return Jan3AuthState.authenticated(profile: response.body!);
    }
    return const Jan3AuthState.unauthenticated();
  }

  Future<void> sendOtp(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = await ref.read(jan3ApiServiceProvider.future);
      final response = await api.login(LoginRequest(email: email));
      if (response.isSuccessful) {
        _logger.debug('[Jan3Account] Successfully sent OTP to: $email');
        if (kDebugMode) {
          _logger.debug('[Jan3Account] ${response.body}');
        }
        return const Jan3AuthState.pendingOtpVerification();
      } else {
        throw ProfileGeneralErrorException();
      }
    });
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = await ref.read(jan3ApiServiceProvider.future);
      final tokenResponse = await api.verify(VerifyRequest(
        email: email,
        otpCode: otp,
      ));
      if (tokenResponse.isSuccessful && tokenResponse.body != null) {
        await _saveToken(tokenResponse.body!);
        // Auto-create a debit card if none exists
        final cards = await ref.read(moonCardsProvider.future);
        if (cards.isEmpty) {
          await ref.read(moonCardsProvider.notifier).createDebitCard();
        }
        final profile = await _getProfile();
        return Jan3AuthState.authenticated(profile: profile);
      }
      throw ProfileAuthErrorException();
    });
  }

  Future<ProfileResponse> _getProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = await ref.read(jan3ApiServiceProvider.future);
      final profile = await api.getUser();
      if (profile.isSuccessful && profile.body != null) {
        _logger.debug('[Jan3Account] Successfully verified OTP');
        return Jan3AuthState.authenticated(profile: profile.body!);
      }
      throw ProfileAuthErrorException();
    });
    throw ProfileGeneralErrorException();
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await ref.read(secureStorageProvider).delete(tokenKey);
    state = const AsyncValue.data(Jan3AuthState.unauthenticated());
  }

  //NOTE - ONLY FOR DEV USAGE
  Future<void> resetAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final tokenResponse = await _tokenResponse;
      if (tokenResponse == null) {
        return const Jan3AuthState.unauthenticated();
      }
      final api = await ref.read(jan3ApiServiceProvider.future);
      final accessTokenResponse = await api.resetAccount();
      if (accessTokenResponse.isSuccessful &&
          accessTokenResponse.body != null) {
        await _saveToken(AuthTokenResponse(
          access: accessTokenResponse.body!.access,
          refresh: accessTokenResponse.body!.refresh,
        ));
        final profile = await _getProfile();
        return Jan3AuthState.authenticated(profile: profile);
      }
      throw ProfileAuthErrorException();
    });
  }

  Future<void> _saveToken(AuthTokenResponse tokenResponse) async {
    await ref.read(secureStorageProvider).delete(tokenKey);
    await ref.read(secureStorageProvider).save(
          key: tokenKey,
          value: jsonEncode(tokenResponse.toJson()),
        );
  }

  Future<void> _refreshToken() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final tokenResponse = await _tokenResponse;
      if (tokenResponse == null) {
        return const Jan3AuthState.unauthenticated();
      }
      final api = await ref.read(jan3ApiServiceProvider.future);
      final accessTokenResponse = await api.refresh(RefreshTokenRequest(
        refresh: tokenResponse.refresh,
      ));
      if (accessTokenResponse.isSuccessful &&
          accessTokenResponse.body != null) {
        await _saveToken(AuthTokenResponse(
          access: accessTokenResponse.body!.access,
          refresh: tokenResponse.refresh,
        ));
        final profile = await _getProfile();
        return Jan3AuthState.authenticated(profile: profile);
      }
      throw ProfileAuthErrorException();
    });
  }

  Future<void> onUnauthorized() async {
    final tokenResponse = await _tokenResponse;
    if (tokenResponse != null) {
      await _refreshToken();
    } else if (state.valueOrNull !=
        const Jan3AuthState.pendingOtpVerification()) {
      signOut();
    }
  }
}
