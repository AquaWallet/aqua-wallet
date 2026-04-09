import 'dart:convert';

import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/feature_flags/services/feature_flags_service.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/settings/language/models/language.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';
import 'package:flutter/foundation.dart';

final _logger = CustomLogger(FeatureFlag.jan3Account);

final jan3AuthProvider =
    AsyncNotifierProvider.family<Jan3AuthNotifier, Jan3AuthState, String>(
        Jan3AuthNotifier.new);

class Jan3AuthNotifier extends FamilyAsyncNotifier<Jan3AuthState, String> {
  @override
  Future<Jan3AuthState> build(String arg) async {
    final walletId = arg;
    // Avoid calls to the build method with empty wallet ID.
    if (walletId.isEmpty) return const Jan3AuthState.unauthenticated();

    final tokenManager = ref.watch(jan3AuthTokenManagerProvider(walletId));
    final token = await tokenManager.getAccessToken();
    if (token != null) {
      final api = await ref.read(jan3ApiServiceProvider.future);
      final response = await api.getUser();

      // If authenticated, store user profile in the wallet
      if (response.isSuccessful && response.body != null) {
        await _storeProfileInWallet(response.body!);
        return Jan3AuthState.authenticated(profile: response.body!);
      }
    }

    // Check if this wallet has a stored profile
    final wallet = await _getCurrentWallet();
    if (wallet?.profileResponse != null) {
      // Wallet has a stored profile but no token — restore auth state
      final restored = await _restoreAuthFromWallet(wallet!);
      if (restored != null) return restored;
    }

    return const Jan3AuthState.unauthenticated();
  }

  Future<StoredWallet?> _getCurrentWallet() async {
    final walletState = await ref.read(storedWalletsProvider.future);
    return walletState.getWalletById(arg);
  }

  Future<void> _onVerified({required bool pendingCardCreation}) async {
    await _refreshProfileData(pendingCardCreation: pendingCardCreation);
    await _refreshFeatureFlags();
  }

  /// Store the profile in the specific wallet this notifier belongs to.
  Future<void> _storeProfileInWallet(ProfileResponse profile) async {
    final wallet = await _getCurrentWallet();
    if (wallet != null) {
      // Only update if the profile is different
      if (wallet.profileResponse != profile) {
        final tokenManager = ref.watch(jan3AuthTokenManagerProvider(arg));
        final token = await tokenManager.readTokenWithoutRefresh();

        await ref
            .read(storedWalletsProvider.notifier)
            .updateWalletWithProfile(wallet.id, profile, token);
      }
    }
  }

  /// Signs out any other wallet that already has the same Jan3 user ID logged in.
  /// Called after a successful login to prevent duplicate sessions.
  Future<void> _signOutConflictingWallets(String userId) async {
    final walletState = await ref.read(storedWalletsProvider.future);
    final conflicting = walletState.wallets
        .where((w) => w.id != arg && w.profileResponse?.id == userId)
        .toList();
    await Future.wait(
      conflicting.map((w) async {
        // Clear token from secure storage and profile from the stored wallet
        // invalidate the auth provider so its next build() sees the cleared
        await ref.read(jan3AuthTokenManagerProvider(w.id)).deleteToken();
        await ref
            .read(storedWalletsProvider.notifier)
            .updateWalletWithProfile(w.id, null, null);
        ref.invalidate(jan3AuthProvider(w.id));
      }),
    );
  }

  /// Restore auth state from the wallet's stored profile and token.
  Future<Jan3AuthState?> _restoreAuthFromWallet(StoredWallet wallet) async {
    if (wallet.profileResponse != null && wallet.authToken != null) {
      _logger.debug(
          '[Jan3Account] Found stored profile and token in wallet, restoring auth state');

      // Save the token from the wallet to secure storage
      final tokenManager = ref.read(jan3AuthTokenManagerProvider(arg));
      await tokenManager.storage.delete(tokenManager.tokenKey);
      await tokenManager.storage.save(
        key: tokenManager.tokenKey,
        value: jsonEncode(wallet.authToken!.toJson()),
      );

      _logger.debug('[Jan3Account] Successfully restored auth state');
      return Jan3AuthState.authenticated(profile: wallet.profileResponse!);
    } else if (wallet.profileResponse != null) {
      _logger.debug(
          '[Jan3Account] Found stored profile in wallet, but no valid token');
    }
    return null;
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
      await ref
          .read(jan3AuthTokenManagerProvider(arg))
          .saveToken(tokenResponse);
      final cards = await ref.read(moonCardsProvider.future);
      await _onVerified(pendingCardCreation: cards.isEmpty);
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

      // Store the profile in the wallet
      await _storeProfileInWallet(profile.body!);
      await _signOutConflictingWallets(profile.body!.id);

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
    await ref.read(jan3AuthTokenManagerProvider(arg)).deleteToken();

    // Remove the profile and auth token from the wallet
    final wallet = await _getCurrentWallet();
    if (wallet != null && wallet.profileResponse != null) {
      await ref
          .read(storedWalletsProvider.notifier)
          .updateWalletWithProfile(arg, null, null);
    }

    state = const AsyncValue.data(Jan3AuthState.unauthenticated());
  }

  //NOTE - ONLY FOR DEV USAGE
  Future<void> resetAccount() async {
    final tokenManager = ref.read(jan3AuthTokenManagerProvider(arg));
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
    final tokenProvider = ref.read(jan3AuthTokenManagerProvider(arg));
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
