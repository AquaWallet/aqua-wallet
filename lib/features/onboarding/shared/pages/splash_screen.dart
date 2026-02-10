import 'package:aqua/features/onboarding/shared/widgets/widgets.dart';
import 'package:aqua/features/onboarding/welcome/widgets/widgets.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class SplashScreen extends HookConsumerWidget {
  static const routeName = '/splash';
  static const double _bottomSpacingHeight = 56 + 20 + 56;

  const SplashScreen({super.key, required this.description});

  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String selectedTagline = description;

    final botevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (botevMode) {
          ref.read(systemOverlayColorProvider(context)).forceDark();
        } else {
          ref.read(systemOverlayColorProvider(context)).custom(
                statusBarColor: AquaPrimitiveColors.aquaBlue300,
                navBarColor: AquaPrimitiveColors.aquaBlue300,
              );
        }
        ref.invalidate(availableAssetsProvider);
      });
      return null;
    }, []);

    if (botevMode) {
      return LayoutBuilder(
        builder: (_, constraints) => UiAssets.botevSplashScreen.image(
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        ),
      );
    }

    return Material(
      color: AquaPrimitiveColors.aquaBlue300,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 48),
                AquaIcon.aquaLogo(
                  size: 40,
                  color: AquaPrimitiveColors.palatinateBlue750,
                ),
                // const Expanded(flex: 2, child: SizedBox.shrink()),
                const Spacer(),
                Center(
                  child: SplashTaglineText(text: selectedTagline),
                ),
                const Spacer(),
                const SizedBox(height: _bottomSpacingHeight),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: WelcomeToSDisclaimer(
                      textColor: AquaPrimitiveColors.aquaBlue300,
                      canLaunch: false,
                    )),
                // const Expanded(flex: 5, child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
