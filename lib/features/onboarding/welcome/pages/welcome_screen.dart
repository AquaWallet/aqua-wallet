import 'dart:async';

import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/provider.dart';
import 'package:aqua/features/auth/auth.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

const _fadeAnimationDuration = Duration(milliseconds: 300);
const _slideAnimationDuration = Duration(milliseconds: 500);

class WelcomeScreen extends HookConsumerWidget {
  static const routeName = '/welcome';

  const WelcomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //ANCHOR - Slide animation
    final slideAnimationController =
        useAnimationController(duration: _slideAnimationDuration);

    useEffect(() {
      Future.delayed(
        _fadeAnimationDuration,
        () => slideAnimationController.forward(),
      );
      return null;
    }, []);

    //ANCHOR - Fade animation
    final fadeAnimationController =
        useAnimationController(duration: _fadeAnimationDuration);

    useEffect(() {
      Future.delayed(
        _fadeAnimationDuration,
        () => fadeAnimationController.forward(),
      );
      return null;
    }, []);

    //ANCHOR - Force status bar colors
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 250), () {
        ref.read(systemOverlayColorProvider(context)).aqua(aquaColorNav: true);
      });
      return null;
    }, []);

    //ANCHOR - Environment switch listener
    ref.listen(
      tapEnvSwitchProvider,
      (_, __) {
        context.push(EnvSwitchScreen.routeName);
      },
    );

    //ANCHOR - Wallet generation/restoration process listener
    ref.listen(registerWalletProcessingProvider, (_, value) {
      value?.maybeWhen(
        loading: () => showGeneralDialog(
          context: context,
          pageBuilder: (_, __, ___) => const WalletProcessingAnimation(
            type: WalletProcessType.create,
          ),
        ),
        error: (_, __) => showDialog(
          context: context,
          builder: (context) => const WalletProcessError(),
        ),
        orElse: () {},
      );
    });

    //ANCHOR - Listen for restore errors
    ref.listen(walletRestoreProvider, (_, state) {
      state.maybeWhen(
        error: (error, _) {
          if (error is WalletRestoreInvalidMnemonicException) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AquaModalSheet.show(
                context,
                colors: context.aquaColors,
                copiedToClipboardText: context.loc.copiedToClipboard,
                title: context.loc.restoreInputError,
                message: context.loc.restoreInputErrorSubtitle,
                primaryButtonText: context.loc.tryAgain,
                onPrimaryButtonTap: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  context
                    ..popUntilPath(AuthWrapper.routeName)
                    ..push(WalletRestoreInputScreen.routeName);
                },
                icon: AquaIcon.danger(color: Colors.white),
                iconVariant: AquaRingedIconVariant.warning,
              );
            });
          }
        },
        orElse: () {},
      );
    });

    final onCreateWallet = useCallback(() async {
      final name = await context.push(EditWalletScreen.routeName) as String?;
      if (name == null) return;

      ref.read(registerWalletProvider).register(walletName: name);
      ref
          .read(walletSuccessModalProvider.notifier)
          .showModal(WalletSuccessModalType.created);
    }, [context]);

    return Theme(
      data: AquaLightTheme().themeData,
      child: Scaffold(
        backgroundColor: AquaPrimitiveColors.aquaBlue300,
        //ANCHOR - Wallet Menu
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 68),
                AquaIcon.aquaLogo(
                  size: 40,
                  color: AquaPrimitiveColors.palatinateBlue750,
                ),
                const Spacer(),
                //ANCHOR - Create Button
                AquaButton.primary(
                  key: OnboardingScreenKeys.welcomeCreateButton,
                  onPressed: () => onCreateWallet(),
                  text: context.loc.createWallet,
                  isInverted: true,
                ),
                const SizedBox(height: 20.0),
                //ANCHOR - Restore Button
                AquaButton.tertiary(
                  key: OnboardingScreenKeys.welcomeRestoreButton,
                  isInverted: true,
                  text: context.loc.restoreWallet,
                  onPressed: () => context
                    ..popUntilPath(AuthWrapper.routeName)
                    ..push(WalletRestoreScreen.routeName),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: WelcomeToSDisclaimer(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
