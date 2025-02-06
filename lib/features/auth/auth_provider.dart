import 'package:aqua/features/auth/models/auth_model.dart';
import 'package:aqua/features/pin/pin_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

final authDepsProvider = Provider<AsyncValue<AuthDepsData>>((ref) {
  final pinAuthState = ref.watch(pinAuthProvider);
  final canAuthenticateWithBiometric = ref.watch(biometricAuthProvider);

  if (pinAuthState.isLoading || canAuthenticateWithBiometric.isLoading) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data(
    AuthDepsData(
        pinState: pinAuthState.value!,
        canAuthenticateWithBiometric:
            canAuthenticateWithBiometric.value!.available),
  );
});
