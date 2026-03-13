import 'package:aqua/features/onboarding/shared/widgets/widgets.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class SplashScreen extends HookConsumerWidget {
  static const routeName = '/splash';

  const SplashScreen({super.key, required this.tagline});

  final String tagline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Theme(
      data: AquaLightTheme().themeData,
      child: Scaffold(
        backgroundColor: AquaPrimitiveColors.aquaBlue300,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 5),
              AquaIcon.aquaLogo(
                size: 40,
                color: AquaPrimitiveColors.palatinateBlue750,
              ),
              const Spacer(flex: 33),
              Flexible(
                flex: 31,
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: SplashTaglineText(text: tagline),
                  ),
                ),
              ),
              const Spacer(flex: 31)
            ],
          ),
        ),
      ),
    );
  }
}
