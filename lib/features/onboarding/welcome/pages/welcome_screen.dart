import 'dart:async';

import 'package:aqua/data/provider/register_wallet/register_wallet_provider.dart';
import 'package:aqua/features/auth/auth_wrapper.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/common/common.dart';
import 'package:aqua/features/onboarding/keys/onboarding_screen_keys.dart';
import 'package:aqua/config/config.dart';

const _fadeAnimationDuration = Duration(milliseconds: 300);
const _slideAnimationDuration = Duration(milliseconds: 500);

class WelcomeScreen extends HookConsumerWidget {
  static const routeName = '/welcome';

  const WelcomeScreen({
    super.key,
    this.description,
    this.onSwitchTagline,
  });

  final String? description;
  final VoidCallback? onSwitchTagline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.read(lightThemeProvider(context)).colorScheme;
    final colors = ref.read(lightThemeProvider(context)).colors;
    final tosAccepted = useState(false);

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
    final fadeAnimation = useAnimation(CurvedAnimation(
      parent: fadeAnimationController,
      curve: Curves.easeOut,
    ));

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

    final buttonStyle = useMemoized(() {
      return ElevatedButton.styleFrom(
        backgroundColor: colors.background,
        foregroundColor: colors.onBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9.0),
        ),
        textStyle: const TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          fontFamily: UiFontFamily.dMSans,
        ),
      );
    });

    final throttler = useMemoized(() => Throttler(milliseconds: 3000));
    useEffect(() => throttler.dispose, []);

    final showUnacceptedConditionError = useCallback(() {
      throttler.run(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('welcome-unaccepted-condition'),
            content: Text(
              !tosAccepted.value
                  ? context.loc.welcomeScreenUnacceptedToSError
                  : context.loc.welcomeScreenUnacceptedDisclaimerError,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onError,
                  ),
            ),
            backgroundColor: colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }, [tosAccepted.value]);

    final changeStatusBarColor = useCallback(() {
      return Future.microtask(
        () => ref.read(systemOverlayColorProvider(context)).forceLight(),
      );
    }, []);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 75.0),
            //ANCHOR - Logo
            GestureDetector(
              child: Container(
                margin: const EdgeInsetsDirectional.only(end: 9.0),
                child: UiAssets.svgs.aquaLogoColorSpaced.svg(
                  height: 59.3,
                ),
              ),
            ),
            const Spacer(),
            //ANCHOR - Tagline
            OnboardingTagline(
              description: description ?? context.loc.welcomeScreenDesc1,
              onTap: onSwitchTagline,
              onLongPress: () => context.push(SplashScreen.routeName),
            ),
            const Spacer(),
            //ANCHOR - Wallet Menu
            AnimatedOpacity(
              opacity: fadeAnimation,
              duration: const Duration(milliseconds: 500),
              child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WelcomeToSCheckbox(onTosAccepted: tosAccepted),
                        const SizedBox(height: 20),
                        //ANCHOR - Create Button
                        AquaElevatedButton(
                          key: OnboardingScreenKeys.welcomeCreateButton,
                          style: buttonStyle,
                          onPressed: () {
                            if (!tosAccepted.value) {
                              return showUnacceptedConditionError();
                            }
                            changeStatusBarColor();
                            ref.read(registerWalletProvider).register();
                          },
                          child: Text(context.loc.createWallet),
                        ),
                        const SizedBox(height: 20.0),
                        //ANCHOR - Restore Button
                        AquaElevatedButton(
                          key: OnboardingScreenKeys.welcomeRestoreButton,
                          style: buttonStyle,
                          onPressed: () {
                            if (!tosAccepted.value) {
                              return showUnacceptedConditionError();
                            }
                            changeStatusBarColor();

                            context
                              ..popUntilPath(AuthWrapper.routeName)
                              ..push(
                                WalletRestoreScreen.routeName,
                              );
                          },
                          child: Text(context.loc.restoreWallet),
                        ),
                        const SizedBox(height: 9.0),
                      ],
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
