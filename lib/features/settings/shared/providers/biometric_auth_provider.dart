import 'dart:async';

import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:local_auth/local_auth.dart';

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
    final auth = ref.read(localAuthProvider);
    final biometricEnabled =
        ref.watch(prefsProvider.select((p) => p.isBiometricEnabled));
    final biometrics = await auth.getAvailableBiometrics();
    final isDeviceSupported = await auth.canCheckBiometrics;
    final canAuthenticateWithBiometric = isDeviceSupported &&
        biometrics.any((type) => kStrongBiometricTypes.contains(type));

    // If biometric auth is enabled but not available, disable it
    if (biometricEnabled && !canAuthenticateWithBiometric) {
      logger.d('[BiometricAuth] Biometric auth enabled but not available');
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
    return ref.read(localAuthProvider).authenticate(
          localizedReason: reason,
          options: const AuthenticationOptions(
            stickyAuth: true,
          ),
        );
  }
}
