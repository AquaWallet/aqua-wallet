import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/feature_flags/services/feature_flags_service.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/settings/language/models/language.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:flutter/foundation.dart';

final _logger = CustomLogger(FeatureFlag.jan3Account);

final jan3AuthProvider = AsyncNotifierProvider<Jan3AuthNotifier, Jan3AuthState>(
    Jan3AuthNotifier.new);

class Jan3AuthNotifier extends AsyncNotifier<Jan3AuthState> {
  @override
  Future<Jan3AuthState> build() async {
    final tokenManager = ref.watch(jan3AuthTokenManagerProvider);
    final token = await tokenManager.getAccessToken();
    if (token != null) {
      final api = await ref.read(jan3ApiServiceProvider.future);
      final response = await api.getUser();
      return Jan3AuthState.authenticated(profile: response.body!);
    }
    return const Jan3AuthState.unauthenticated();
  }

  Future<void> sendOtp(String email, Language currentLang) async {
    state = const AsyncData(Jan3AuthState.unauthenticated());
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = await ref.read(jan3ApiServiceProvider.future);
      final response = await api.login(LoginRequest(
        email: email,
        language: currentLang.toAnkaraLanguage,
      ));
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
    final api = await ref.read(jan3ApiServiceProvider.future);
    final tokenResponse = await api.verify(VerifyRequest(
      email: email,
      otpCode: otp,
    ));
    if (tokenResponse.isSuccessful && tokenResponse.body != null) {
      await ref.read(jan3AuthTokenManagerProvider).saveToken(tokenResponse);
      final cards = await ref.read(moonCardsProvider.future);
      await _refreshProfileData(pendingCardCreation: cards.isEmpty);
      await _refreshFeatureFlags();
    } else {
      state = AsyncValue.error(ProfileAuthErrorException(), StackTrace.current);
    }
  }

  Future<void> _refreshProfileData({
    bool pendingCardCreation = false,
  }) async {
    state = const AsyncValue.loading();

    final api = await ref.read(jan3ApiServiceProvider.future);
    final profile = await api.getUser();
    if (profile.isSuccessful && profile.body != null) {
      _logger.debug('[Jan3Account] Successfully refreshed profile data');
      state = AsyncValue.data(
        Jan3AuthState.authenticated(
          profile: profile.body!,
          pendingCardCreation: pendingCardCreation,
        ),
      );
    } else {
      state = const AsyncValue.data(Jan3AuthState.unauthenticated());
    }
  }

  Future<void> _refreshFeatureFlags() async {
    ref.invalidate(featureFlagsServiceProvider);
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await ref.read(jan3AuthTokenManagerProvider).deleteToken();
    state = const AsyncValue.data(Jan3AuthState.unauthenticated());
  }

  //NOTE - ONLY FOR DEV USAGE
  Future<void> resetAccount() async {
    final tokenManager = ref.read(jan3AuthTokenManagerProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final token = await tokenManager.getAccessToken();

      if (token == null) {
        return const Jan3AuthState.unauthenticated();
      }
      final api = await ref.read(jan3ApiServiceProvider.future);
      final accessTokenResponse = await api.resetAccount();
      if (accessTokenResponse.isSuccessful &&
          accessTokenResponse.body != null) {
        await tokenManager.saveToken(accessTokenResponse);
        await _refreshProfileData();
      }
      throw ProfileAuthErrorException();
    });
  }

  Future<void> onUnauthorized() async {
    final tokenProvider = ref.read(jan3AuthTokenManagerProvider);
    try {
      final token = await tokenProvider.getAccessToken();

      if (token != null) {
        _logger.warning(
            '[Jan3Account] Recieved unauthorized with valid token, forcing sign out');
        await tokenProvider.deleteToken();
        signOut();
        return;
      }

      if (state.valueOrNull is! Jan3UserPendingOtpVerification) {
        _logger.debug('[Jan3Account] Token is null, signing out');
        _logger.debug('[Jan3Account] State: ${state.valueOrNull}');
        signOut();
      }
    } catch (e) {
      _logger.error('[Jan3Account] Error during unauthorized: $e');
      signOut();
    }
  }
}
