import 'dart:io';

import 'package:aqua/common/common.dart';
import 'package:aqua/features/auth/auth_provider.dart';
import 'package:aqua/features/onboarding/shared/shared.dart';
import 'package:aqua/features/pin/pin_provider.dart';
import 'package:aqua/features/pin/pin_screen.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ui_components/ui_components.dart' hide AquaColors;

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
    final biometricState = ref.watch(biometricAuthProvider).asData?.value;
    final primaryBiometricType = biometricState?.primaryBiometricType;

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
    }, [biometricAuthEnabled]);

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

    return Theme(
      data: AquaLightTheme().themeData,
      child: Scaffold(
        backgroundColor: AquaPrimitiveColors.aquaBlue300,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                //ANCHOR - Logo
                const ScreenLogoHeader(),
                const Spacer(),
                //ANCHOR - Lock icon
                AquaRingedIcon(
                  icon: AquaIcon.lock(color: Colors.white),
                  variant: AquaRingedIconVariant.accent,
                  colors: context.aquaColors,
                ),
                const SizedBox(height: 24),
                //ANCHOR - Description
                AquaText.h4SemiBold(
                  text: context.loc.authScreenDescription,
                  color: AquaPrimitiveColors.palatinateBlue750,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 16,
                ),
                AquaText.body1(
                  text: primaryBiometricType
                      .authScreenBiometricSubdescription(context),
                  color: AquaPrimitiveColors.palatinateBlue750,
                ),
                const Spacer(),
                //ANCHOR - Biometric unlock button
                if (biometricAuthEnabled)
                  AquaButton.primary(
                    isInverted: true,
                    text: primaryBiometricType
                        .authScreenBiometricButtonText(context),
                    onPressed: requestBiometricAuth,
                  ),
                //ANCHOR - PIN unlock button (only when both biometric + PIN enabled)
                if (biometricAuthEnabled &&
                    authDeps.asData?.value.pinState !=
                        PinAuthState.disabled) ...[
                  const SizedBox(height: 20),
                  AquaButton.tertiary(
                    isInverted: true,
                    text: context.loc.authScreenUnlockWithPinButton,
                    onPressed: requestPinAuth,
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _AuthBiometricStrings on BiometricType? {
  String authScreenBiometricButtonText(BuildContext context) {
    final loc = context.loc;
    return switch (this) {
      BiometricType.face => loc.authScreenUnlockWithFaceId,
      BiometricType.fingerprint => Platform.isIOS
          ? loc.authScreenUnlockWithTouchId
          : loc.authScreenUnlockWithFingerprint,
      _ => loc.authScreenUnlockWithBiometricsButton,
    };
  }

  String authScreenBiometricSubdescription(BuildContext context) {
    final loc = context.loc;
    return switch (this) {
      BiometricType.face => loc.authScreenSubdescriptionFace,
      BiometricType.fingerprint => Platform.isIOS
          ? loc.authScreenSubdescriptionTouchId
          : loc.authScreenSubdescriptionFingerprint,
      _ => loc.authScreenSubdescription,
    };
  }
}
