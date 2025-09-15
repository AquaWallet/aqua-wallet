import 'dart:async';

import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SplashScreen extends HookConsumerWidget {
  static const routeName = '/splash';

  const SplashScreen({
    super.key,
    this.description,
    this.onSwitchTagline,
  });

  final String? description;
  final VoidCallback? onSwitchTagline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final botevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));

    useEffect(() {
      Future.microtask(() {
        if (botevMode) {
          ref.read(systemOverlayColorProvider(context)).forceDark();
        } else {
          ref
              .read(systemOverlayColorProvider(context))
              .aqua(aquaColorNav: true);
        }
        ref.invalidate(availableAssetsProvider);
      });
      return null;
    }, []);

    if (botevMode) {
      return LayoutBuilder(
        builder: (_, constraints) => UiAssets.botevSplashScreenWebp.image(
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 75.0),
          //ANCHOR - Logo
          Container(
            margin: const EdgeInsetsDirectional.only(end: 9.0),
            child: UiAssets.svgs.aquaLogoColorSpaced.svg(
              height: 59.3,
            ),
          ),
          const Spacer(),
          //ANCHOR - Tagline
          OnboardingTagline(
            description: description ?? context.loc.welcomeScreenDesc1,
            onTap: onSwitchTagline,
            onLongPress: () => context.push(WelcomeScreen.routeName),
          ),
          const Spacer(),
          const SizedBox(height: 194.0),
        ],
      ),
    );
  }
}
