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
              const ScreenLogoHeader(),
              const Spacer(flex: 12),
              Flexible(
                flex: 31,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SplashTaglineText(text: tagline),
                ),
              ),
              const Spacer(flex: 22)
            ],
          ),
        ),
      ),
    );
  }
}
