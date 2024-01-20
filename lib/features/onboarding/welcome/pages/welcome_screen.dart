import 'dart:async';

import 'package:aqua/data/provider/register_wallet/register_wallet_provider.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const _fadeAnimationDuration = Duration(milliseconds: 300);
const _slideAnimationDuration = Duration(milliseconds: 500);

class WelcomeScreen extends HookConsumerWidget {
  static const routeName = '/welcome';

  const WelcomeScreen({
    Key? key,
    this.description = '',
  }) : super(key: key);

  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //ANCHOR - Slide animation
    final slideAnimationController =
        useAnimationController(duration: _slideAnimationDuration);
    final slideAnimation = Tween(begin: const Offset(0, 2.2), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: slideAnimationController,
      curve: Curves.easeOut,
    ));

    useEffect(() {
      Future.delayed(
        _fadeAnimationDuration,
        () => slideAnimationController.forward(),
      );
      return () => slideAnimationController.dispose();
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
      return () => fadeAnimationController.dispose();
    }, []);

    //ANCHOR - Force status bar colors
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 250), () {
        ref.read(systemOverlayColorProvider(context)).aqua();
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

    return Scaffold(
      body: Stack(
        children: [
          const SplashBackground(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 15),
              //ANCHOR - Logo
              SlideTransition(
                position: slideAnimation,
                child: OnboardingAppLogo(
                  description: description,
                  onLongPress: () => unawaited(Navigator.of(context)
                      .pushReplacementNamed(SplashScreen.routeName)),
                  onTap: () {
                    ref.read(envSwitchProvider).setTapEnv();
                  },
                ),
              ),
              const Spacer(flex: 8),
              //ANCHOR - Wallet Menu
              AnimatedOpacity(
                opacity: fadeAnimation,
                duration: const Duration(milliseconds: 500),
                child: const WalletMenuSheet(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
