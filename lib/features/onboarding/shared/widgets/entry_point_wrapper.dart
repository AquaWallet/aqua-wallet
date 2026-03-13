import 'dart:math';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/desktop/pages/desktop_home_screen.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/shared/constants/constants.dart';

enum _EntryScreenKey {
  splash,
  welcome,
  home,
  desktopHome,
}

class EntryPointWrapper extends HookConsumerWidget {
  const EntryPointWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagLines = useMemoized(
        () => [
              context.loc.welcomeScreenDesc1,
              context.loc.welcomeScreenDesc2,
              context.loc.welcomeScreenDesc3,
              context.loc.welcomeScreenDesc4,
              context.loc.welcomeScreenDesc5,
              context.loc.welcomeScreenDesc6,
            ],
        [context.loc]);

    final selectedTagline = useMemoized(
      () => tagLines[Random().nextInt(tagLines.length)],
      [tagLines],
    );

    final initAppState = ref.watch(initAppProvider);
    final storedWalletsState = ref.watch(storedWalletsProvider);
    final aquaConnectionState = ref.watch(aquaConnectionProvider);

    ref.listen(storedWalletsProvider, (prev, next) {
      next.whenData((walletState) {
        final hadNoWallet = prev?.valueOrNull?.currentWallet == null;
        final hasWallet = walletState.currentWallet != null;
        final currentRoute =
            GoRouter.of(context).routeInformationProvider.value.uri.path;

        if (hadNoWallet && hasWallet && currentRoute == '/') {
          context.pushReplacement(HomeScreen.routeName);
        }
      });
    });

    final currentScreen = initAppState.maybeWhen(
      data: (_) => storedWalletsState.when(
        data: (walletState) {
          if (walletState.currentWallet != null) {
            return aquaConnectionState.when(
              data: (_) => isDesktop
                  ? DesktopHomeScreen(
                      key: ValueKey(_EntryScreenKey.desktopHome.name),
                    )
                  : HomeScreen(
                      key: ValueKey(_EntryScreenKey.home.name),
                    ),
              error: (_, __) => HomeScreen(
                key: ValueKey(_EntryScreenKey.home.name),
              ),
              loading: () => SplashScreen(
                key: ValueKey(_EntryScreenKey.splash.name),
                tagline: selectedTagline,
              ),
            );
          }
          return WelcomeScreen(
            key: ValueKey(_EntryScreenKey.welcome.name),
          );
        },
        loading: () => SplashScreen(
          key: ValueKey(_EntryScreenKey.splash.name),
          tagline: selectedTagline,
        ),
        error: (_, __) => WelcomeScreen(
          key: ValueKey(_EntryScreenKey.welcome.name),
        ),
      ),
      orElse: () => SplashScreen(
        key: ValueKey(_EntryScreenKey.splash.name),
        tagline: selectedTagline,
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: currentScreen,
    );
  }
}
