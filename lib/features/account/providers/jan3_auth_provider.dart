import 'dart:convert';

import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/feature_flags/services/feature_flags_service.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/settings/language/models/language.dart';
import 'package:aqua/features/wallet/wallet.dart';
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

      // If authenticated, store user profile in the current wallet
      if (response.isSuccessful && response.body != null) {
        await _storeProfileInCurrentWallet(response.body!);
        return Jan3AuthState.authenticated(profile: response.body!);
      }
    }

    // Check if the current wallet has a stored profile
    final walletState = await ref.read(storedWalletsProvider.future);
    if (walletState.currentWallet?.profileResponse != null) {
      // If the wallet has a stored profile but we don't have a token, restore the auth state
      await _restoreAuthFromWallet(walletState.currentWallet!);
    }

    return const Jan3AuthState.unauthenticated();
  }

  // Store the profile in the current wallet
  Future<void> _storeProfileInCurrentWallet(ProfileResponse profile) async {
    final walletState = await ref.read(storedWalletsProvider.future);
    final currentWallet = walletState.currentWallet;
    if (currentWallet != null) {
      // Only update if the profile is different
      if (currentWallet.profileResponse?.id != profile.id) {
        // Get the current token to store with the profile
        final tokenManager = ref.watch(jan3AuthTokenManagerProvider);
        final token = await tokenManager.readTokenWithoutRefresh();

        final updatedWallet = currentWallet.copyWith(
          profileResponse: profile,
          authToken: token,
        );

        // Get the wallets notifier and update the wallet
        await ref
            .read(storedWalletsProvider.notifier)
            .updateWalletWithProfile(updatedWallet.id, profile, token);
      }
    }
  }

  // Restore auth state from wallet's stored profile
  Future<void> _restoreAuthFromWallet(StoredWallet wallet) async {
    if (wallet.profileResponse != null && wallet.authToken != null) {
      _logger.debug(
          '[Jan3Account] Found stored profile and token in wallet, restoring auth state');

      // Save the token from the wallet to secure storage
      // We need to save the token directly to storage since we have AuthTokenResponse, not Response<AuthTokenResponse>
      final tokenManager = ref.read(jan3AuthTokenManagerProvider);
      await tokenManager.storage.delete(Jan3AuthTokenManager.tokenKey);
      await tokenManager.storage.save(
        key: Jan3AuthTokenManager.tokenKey,
        value: jsonEncode(wallet.authToken!.toJson()),
      );

      // Return authenticated state with the stored profile
      state = AsyncValue.data(
        Jan3AuthState.authenticated(profile: wallet.profileResponse!),
      );

      _logger.debug('[Jan3Account] Successfully restored auth state');
    } else if (wallet.profileResponse != null) {
      _logger.debug(
          '[Jan3Account] Found stored profile in wallet, but no valid token');
    }
  }

  Future<void> sendOtp(String email, Language currentLang) async {
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

      // Store the profile in the current wallet
      await _storeProfileInCurrentWallet(profile.body!);

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

    // Remove the profile and auth token from the current wallet
    final walletState = await ref.read(storedWalletsProvider.future);
    final currentWallet = walletState.currentWallet;
    if (currentWallet != null && currentWallet.profileResponse != null) {
      await ref
          .read(storedWalletsProvider.notifier)
          .updateWalletWithProfile(currentWallet.id, null, null);
    }

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
