import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/pin/pin_screen.dart';
import 'package:coin_cz/features/recovery/pages/warning_phrase_screen.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

class PinWarningScreen extends HookConsumerWidget {
  static const routeName = '/setupWarningPin';

  const PinWarningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: const AquaAppBar(
          backgroundColor: Colors.transparent,
          showBackButton: true,
          showActionButton: false,
          iconBackgroundColor: Colors.transparent,
          iconForegroundColor: Colors.white,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppStyle.backgroundGradient,
          ),
          child: Padding(
              padding: const EdgeInsets.all(24.0),
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                const SizedBox(height: 75),
                //ANCHOR - Aqua Logo
                UiAssets.svgs.dark.aquaLogo.svg(
                  width: 321.0,
                ),
                const SizedBox(height: 50),
                Text(
                  textAlign: TextAlign.center,
                  context.loc.pinScreenWarningTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        textAlign: TextAlign.left,
                        context.loc.pinScreenWarningDescription,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      InkWell(
                        onTap: () => context
                            .replace(WalletPhraseWarningScreen.routeName),
                        child: Text(context.loc.pinScreenWarningViewRecovery,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            )),
                      )
                    ],
                  ),
                ),
                const Spacer(),
                AquaElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AquaColors.aquaBlue,
                    ),
                    child: Text(context.loc.pinScreenWarningContinueButton),
                    onPressed: () => context.replace(SetupPinScreen.routeName)),
              ])),
        ));
  }
}
