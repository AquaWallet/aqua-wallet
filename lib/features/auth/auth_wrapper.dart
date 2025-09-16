import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/auth/auth_provider.dart';
import 'package:coin_cz/features/onboarding/onboarding.dart';
import 'package:coin_cz/features/pin/pin_provider.dart';
import 'package:coin_cz/features/pin/pin_screen.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Does the authentication and displays the sensitive information based on its
/// result
class AuthWrapper extends HookConsumerWidget {
  static const routeName = '/';
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authDeps = ref.watch(authDepsProvider);

    final biometricAuthEnabled =
        ref.watch(prefsProvider.select((p) => p.isBiometricEnabled));
    final isAuthenticated = useState(false);
    final isStartupAuthTriggered = useState(false);

    final requestBiometricAuth = useCallback(() async {
      isAuthenticated.value = false;
      isStartupAuthTriggered.value = true;
      final success = await ref
          .read(biometricAuthProvider.notifier)
          .authenticate(reason: context.loc.biometricAuthenticationDescription);
      isAuthenticated.value = success;
    }, []);

    final requestPinAuth = useCallback(() async {
      isAuthenticated.value = false;
      isStartupAuthTriggered.value = true;
      final success = await context.push(CheckPinScreen.routeName,
          extra: CheckPinScreenArguments(
              onSuccessAction: CheckAction.pull,
              canCancel: biometricAuthEnabled)) as bool?;
      isAuthenticated.value = success == true ? true : false;
    }, []);

    //ANCHOR - Force status bar colors
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 250), () {
        ref.read(systemOverlayColorProvider(context)).aqua(aquaColorNav: true);
      });
      return null;
    }, []);

    //ANCHOR - Request auth on screen startup
    useEffect(() {
      if (isStartupAuthTriggered.value || authDeps.isLoading) {
        return null;
      }

      if (biometricAuthEnabled &&
          authDeps.asData?.value.pinState != PinAuthState.locked &&
          authDeps.asData?.value.canAuthenticateWithBiometric == true) {
        Future.delayed(
          const Duration(milliseconds: 250),
          requestBiometricAuth,
        );
      } else if (authDeps.asData?.value.pinState != PinAuthState.disabled) {
        // only PIN is enabled so just show CheckPinScreen
        Future.delayed(
          const Duration(milliseconds: 250),
          requestPinAuth,
        );
      }
      return null;
    }, [authDeps.asData?.value]);

    if (authDeps.isLoading) {
      return const LoadingIndicator();
    }

    if ((!biometricAuthEnabled &&
            authDeps.asData?.value.pinState == PinAuthState.disabled) ||
        isAuthenticated.value) {
      return const EntryPointWrapper();
    }

    if (isStartupAuthTriggered.value == false) {
      return const LoadingIndicator();
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 46),
          //ANCHOR - Logo
          UiAssets.svgs.aquaLogoColorSpaced.svg(
            height: 42,
          ),
          const Spacer(),
          //ANCHOR - Description
          Text(
            context.loc.authScreenDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  height: 1.2,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const SizedBox(
            height: 36,
          ),
          // ANCHOR - Auth Button
          if (biometricAuthEnabled) ...[
            GestureDetector(
              onTap: () => requestBiometricAuth(),
              child: Container(
                width: 140,
                decoration: const BoxDecoration(
                    color: AquaColors.blueGreen,
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                child: AquaTextButton(
                  child: Text(context.loc.authScreenUnlockWithBiometricsButton,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 36),
          if (biometricAuthEnabled &&
              authDeps.asData?.value.pinState != PinAuthState.disabled) ...[
            //ANCHOR - Unlock with PIN
            GestureDetector(
              onTap: () => requestPinAuth(),
              child: Container(
                width: 140,
                decoration: const BoxDecoration(
                    color: AquaColors.blueGreen,
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                child: AquaTextButton(
                    child: Text(
                  context.loc.authScreenUnlockWithPinButton,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white),
                )),
              ),
            ),

            const SizedBox(height: 36),
          ],
          const Spacer(),
          const SizedBox(height: 148),
        ],
      ),
    );
  }
}
