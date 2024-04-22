import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Does the authentication and displays the sensitive information based on its
/// result
class AuthWrapper extends HookConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAuthSuccess = useState(false);
    final biometricAuthEnabled =
        ref.watch(prefsProvider.select((p) => p.isBiometricEnabled));
    final canAuthenticateWithBiometric =
        ref.watch(biometricAuthProvider).asData?.value.available ?? false;

    final requestBiometricAuth = useCallback(() async {
      biometricAuthSuccess.value = false;
      final success = await ref
          .read(biometricAuthProvider.notifier)
          .authenticate(reason: context.loc.biometricAuthenticationDescription);
      biometricAuthSuccess.value = success;
    }, []);

    //ANCHOR - Force status bar colors
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 250), () {
        ref.read(systemOverlayColorProvider(context)).aqua(aquaColorNav: true);
      });
      return null;
    }, []);

    //ANCHOR - Request biometric auth on screen startup
    useEffect(() {
      if (biometricAuthEnabled && canAuthenticateWithBiometric) {
        Future.delayed(
          const Duration(milliseconds: 250),
          requestBiometricAuth,
        );
      }
      return null;
    }, []);

    if (!biometricAuthEnabled || biometricAuthSuccess.value) {
      return const EntryPointWrapper();
    }

    return Stack(
      children: [
        const SplashBackground(),
        Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 10),
              //ANCHOR - Logo
              OnboardingAppLogo(description: context.loc.welcomeScreenDesc1),
              Expanded(
                flex: 7,
                child: Center(
                  child: OutlinedButton(
                    onPressed: requestBiometricAuth,
                    style: OutlinedButton.styleFrom(
                      fixedSize: Size(140.w, 42.h),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Colors.white,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(context.loc.authenticationButtonText),
                  ),
                ),
              ),
              SizedBox(height: 188.h),
            ],
          ),
        ),
      ],
    );
  }
}
