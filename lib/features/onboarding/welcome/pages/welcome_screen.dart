import 'dart:async';

import 'package:aqua/data/provider/register_wallet/register_wallet_provider.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
        Navigator.of(context).pushNamed(EnvSwitchScreen.routeName);
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

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 75.h),
          //ANCHOR - Logo
          GestureDetector(
            child: Container(
              margin: EdgeInsetsDirectional.only(end: 9.w),
              child: UiAssets.svgs.aquaLogoColorSpaced.svg(
                height: 59.3.h,
              ),
            ),
          ),
          const Spacer(),
          //ANCHOR - Tagline
          OnboardingTagline(
            description: description ?? context.loc.welcomeScreenDesc1,
            onTap: onSwitchTagline,
            onLongPress: () =>
                Navigator.of(context).pushNamed(SplashScreen.routeName),
          ),
          const Spacer(),
          //ANCHOR - Wallet Menu
          AnimatedOpacity(
            opacity: fadeAnimation,
            duration: const Duration(milliseconds: 500),
            child: const WalletMenuSheet(),
          ),
        ],
      ),
    );
  }
}
