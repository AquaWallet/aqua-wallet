import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:aqua/features/pin/pin_provider.dart';
import 'package:aqua/features/pin/pin_screen.dart';
import 'package:aqua/features/pin/pin_warning_screen.dart';
import 'package:aqua/features/settings/shared/keys/settings_screen_keys.dart';
import 'package:aqua/features/settings/shared/providers/biometric_auth_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class SecuritySettingsScreen extends HookConsumerWidget {
  const SecuritySettingsScreen({super.key});

  static const routeName = '/settings/security';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAuth = ref.watch(biometricAuthProvider).asData?.value;
    final pinEnabled =
        ref.watch(pinAuthProvider).asData?.value != PinAuthState.disabled;

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        title: context.loc.settingsScreenSectionSecurity,
        colors: context.aquaColors,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (biometricAuth != null &&
                    biometricAuth.isDeviceSupported) ...[
                  AquaListItem(
                    key: SettingsScreenKeys
                        .settingsBiometricAuthenticationButton,
                    iconLeading: AquaIcon.biometricFingerprint(
                      size: 24,
                      color: context.aquaColors.textSecondary,
                    ),
                    iconTrailing: AquaToggle(
                      value: biometricAuth.enabled,
                      trackColor: context.aquaColors.surfaceSecondary,
                    ),
                    title: context.loc.settingsScreenItemBiometricAuth,
                    onTap: () {
                      if (biometricAuth.available) {
                        ref.read(biometricAuthProvider.notifier).toggle(
                              reason: context
                                  .loc.biometricAuthenticationDescription,
                            );
                      } else if (Platform.isAndroid) {
                        // on Android, open settings security screen
                        AppSettings.openAppSettings(
                            type: AppSettingsType.security);
                      } else {
                        // on iOS, security type is not supported, so open general settings
                        AppSettings.openAppSettings();
                      }
                    },
                  ),
                  const SizedBox(height: 1.0),
                ],
                //ANCHOR - PIN
                AquaListItem(
                  iconLeading: AquaIcon.passcode(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  iconTrailing: AquaToggle(
                    value: pinEnabled,
                    trackColor: context.aquaColors.surfaceSecondary,
                  ),
                  title: context.loc.settingsScreenItemPin,
                  onTap: () async {
                    if (!pinEnabled) {
                      context.push(PinWarningScreen.routeName);
                      return;
                    }
                    final success = await context.push(CheckPinScreen.routeName,
                        extra: CheckPinScreenArguments(
                            onSuccessAction: CheckAction.pull,
                            canCancel: true,
                            description:
                                context.loc.pinScreenDisabledDescription));
                    if (success == true) {
                      ref.read(pinAuthProvider.notifier).disable();
                    }
                  },
                ),
                // TODO: Re-enable when require pin is designed
                // if (pinEnabled) ...[
                //   const SizedBox(height: 4.0),
                //   //ANCHOR - Auto Lock
                //   MenuItemWidget.labeledArrow(
                //     context: context,
                //     assetName: UiAssets.shieldCheck.path,
                //     color: context.colors.onBackground,
                //     title: context.loc.autoLockSettingsScreenTitle,
                //     label: _getAutoLockDisplayText(context, currentAutoLock),
                //     onPressed: () =>
                //         context.push(AutoLockSettingsScreen.routeName),
                //   ),
                // ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
