import 'package:aqua/data/provider/provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart';
import 'package:restart_app/restart_app.dart';
import 'package:aqua/utils/utils.dart';

class RestartScreen extends HookConsumerWidget {
  static const routeName = '/restart';

  const RestartScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: ref.watch(newLightThemeProvider(context)),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AquaPrimitiveColors.aquaBlue300,
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 75.0),
                //ANCHOR - Logo
                AquaIcon.aquaLogo(
                  size: 40,
                  color: AquaPrimitiveColors.palatinateBlue750,
                ),
                const Spacer(),
                //ANCHOR - Main Title
                AquaText.h3SemiBold(
                  text: context.loc.walletDeletedRestartScreenTitle,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  color: AquaPrimitiveColors.palatinateBlue750,
                ),
                const SizedBox(height: 4),
                AquaText.body1Medium(
                  text: context.loc.walletDeletedRestartScreenBody,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  color: AquaPrimitiveColors.palatinateBlue750,
                ),
                const Spacer(),
                Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          //ANCHOR - Restart Button
                          AquaButton.primary(
                            onPressed: () => Restart.restartApp(),
                            text: context.loc
                                .walletDeletedRestartScreenRestartButtonTitle,
                            isInverted: true,
                          ),
                          const SizedBox(height: 20.0),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
