import 'package:aqua/data/data.dart';
import 'package:aqua/features/pin/pin_screen.dart';
import 'package:aqua/features/settings/shared/providers/biometric_auth_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

/// A mixin that provides authentication functionality for sensitive operations.
/// This mixin can be used to wrap any method with authentication requirements.
mixin AuthGuardMixin on HookConsumerWidget {
  /// Wraps a function call with authentication.
  /// Returns the result of [operation] if authentication is successful,
  /// otherwise returns [fallback].
  ///
  /// Parameters:
  /// - [context]: The BuildContext for showing dialogs and navigation
  /// - [ref]: The WidgetRef for accessing providers
  /// - [walletId]: The ID of the wallet to authenticate against
  /// - [authDescription]: Custom description for the authentication dialog
  /// - [operation]: The function to execute after successful authentication
  Future<bool> withAuth({
    required Future Function() operation,
    required BuildContext context,
    required WidgetRef ref,
    required String walletId,
    String? authDescription,
  }) async {
    try {
      final storage = ref.read(secureStorageProvider);

      // Check for PIN
      final (pin, _) = await storage.get(StorageKeys.pin);
      final hasPinProtection = pin != null;

      // Check for biometrics
      final (biometricsEnabled, _) =
          await storage.get(StorageKeys.biometricsEnabled);
      final hasBiometrics = biometricsEnabled == 'true';

      // If no authentication is required, execute operation directly
      if (!hasPinProtection && !hasBiometrics) {
        return await operation();
      }

      bool isAuthenticated = false;

      // Try biometric auth first if enabled
      if (hasBiometrics) {
        isAuthenticated =
            await ref.read(biometricAuthProvider.notifier).authenticate(
                  reason: authDescription ?? context.loc.authenticationRequired,
                );
      }

      // If biometrics failed or not available, check PIN
      if (!isAuthenticated && hasPinProtection && context.mounted) {
        // Set temporary wallet ID for PIN verification
        await storage.save(key: StorageKeys.currentWalletId, value: walletId);

        if (!context.mounted) {
          return false;
        }

        final success = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => CheckPinScreen(
              arguments: CheckPinScreenArguments(
                onSuccessAction: CheckAction.pull,
                canCancel: true,
                description:
                    authDescription ?? context.loc.authenticationRequired,
              ),
            ),
          ),
        );

        isAuthenticated = success == true;

        // Reset current wallet ID if auth failed
        if (!isAuthenticated) {
          await storage.delete(StorageKeys.currentWalletId);
        }
      }

      // If authentication failed, return fallback or throw
      if (!isAuthenticated) {
        return false;
      }

      // Authentication successful, execute operation
      return await operation();
    } catch (e) {
      return false;
    }
  }
}
