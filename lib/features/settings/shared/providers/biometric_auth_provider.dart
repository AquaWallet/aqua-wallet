import 'dart:async';

import 'package:aqua/features/pin/pin_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ui_components/shared/constants/constants.dart';

final _logger = CustomLogger(FeatureFlag.biometric);

const kStrongBiometricTypes = [
  BiometricType.strong,
  BiometricType.face,
  BiometricType.fingerprint
];

final biometricAuthProvider =
    AsyncNotifierProvider<BiometricAuthNotifier, BiometricAuthState>(
        BiometricAuthNotifier.new);

final localAuthProvider = Provider((_) => LocalAuthentication());

class BiometricAuthNotifier extends AsyncNotifier<BiometricAuthState> {
  @override
  FutureOr<BiometricAuthState> build() async {
    state = const AsyncValue.loading();
    final auth = ref.read(localAuthProvider);

    bool biometricEnabled = false;
    bool isDeviceSupported = false;
    final biometrics = await auth.getAvailableBiometrics();

    ///TODO: for desktop biometric is not implemented yet
    /// by default it is false
    if (!isDesktop) {
      biometricEnabled =
          ref.watch(prefsProvider.select((p) => p.isBiometricEnabled));
      isDeviceSupported = await auth.canCheckBiometrics;
    }

    final canAuthenticateWithBiometric = isDeviceSupported &&
        biometrics.any((type) => kStrongBiometricTypes.contains(type));

    // If biometric auth is enabled but not available, disable it
    if (biometricEnabled && !canAuthenticateWithBiometric) {
      _logger.debug('Biometric auth enabled but not available');
      await ref.read(prefsProvider).switchBiometricAuth();
    }

    return BiometricAuthState(
      isDeviceSupported: isDeviceSupported,
      available: canAuthenticateWithBiometric,
      enabled: biometricEnabled,
    );
  }

  Future<void> toggle({required String reason}) async {
    // Ask for biometric verification before toggling
    if (await authenticate(reason: reason)) {
      await ref.read(prefsProvider).switchBiometricAuth();
    }
  }

  Future<bool> authenticate({required String reason}) async {
    final isPinEnabled =
        ref.read(pinAuthProvider).asData?.value != PinAuthState.disabled;
    final success = await ref.read(localAuthProvider).authenticate(
          localizedReason: reason,
          options: AuthenticationOptions(
              stickyAuth: true,
              // if PIN is enabled we don't allow OS PIN
              biometricOnly: isPinEnabled),
        );

    // Record successful authentication to prevent double auth prompts
    if (success) {
      ref.read(biometricAuthTrackerProvider).recordSuccessfulAuth();
    } else {
      ref.read(biometricAuthTrackerProvider).recordFailedAuth();
    }

    return success;
  }
}

/// Global tracker for biometric authentication events
/// This helps prevent double authentication prompts when biometric auth
/// from other screens puts the app in background and triggers auto-lock
final biometricAuthTrackerProvider = Provider<BiometricAuthTracker>((ref) {
  return BiometricAuthTracker();
});

class BiometricAuthTracker {
  DateTime? _lastSuccessBiometricAuthTime;
  DateTime? _lastFailBiometricAuthTime;

  /// Records when biometric authentication was successful
  void recordSuccessfulAuth() {
    _lastSuccessBiometricAuthTime = DateTime.now();
    _logger.debug(
        "Recorded successful biometric auth at $_lastSuccessBiometricAuthTime");
  }

  /// Records when biometric authentication was successful
  void recordFailedAuth() {
    _lastFailBiometricAuthTime = DateTime.now();
    _logger.debug(
        "Recorded successful biometric auth at $_lastFailBiometricAuthTime");
  }

  /// Checks if biometric auth happened recently (within the last 5 seconds)
  /// This is used to skip auto-lock if user just authenticated via biometric
  bool wasRecentlyAuthenticated() {
    if (_lastSuccessBiometricAuthTime == null) return false;

    final timeSinceAuth =
        DateTime.now().difference(_lastSuccessBiometricAuthTime!);
    final wasRecent = timeSinceAuth.inSeconds < 5;

    if (wasRecent) {
      _logger.debug(
          "Recent biometric auth success (${timeSinceAuth.inSeconds}s ago)");
    }

    return wasRecent;
  }

  bool wasRecentlyFailed() {
    if (_lastFailBiometricAuthTime == null) return false;

    final timeSinceAuth =
        DateTime.now().difference(_lastFailBiometricAuthTime!);
    final wasRecent = timeSinceAuth.inSeconds < 5;

    if (wasRecent) {
      _logger.debug(
          "Recent biometric auth fail (${timeSinceAuth.inSeconds}s ago)");
    }

    return wasRecent;
  }

  /// Clears the authentication record (useful for testing or manual reset)
  void clearAuthRecord() {
    _lastSuccessBiometricAuthTime = null;
    _lastFailBiometricAuthTime = null;
    _logger.debug("Cleared biometric auth record");
  }
}
