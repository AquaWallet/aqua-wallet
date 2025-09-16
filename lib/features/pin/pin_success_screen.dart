import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

class PinSuccessScreen extends HookConsumerWidget {
  static const routeName = '/setupSuccessPin';

  const PinSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(24.0),
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                const SizedBox(height: 50),
                //ANCHOR - Aqua Logo
                UiAssets.svgs.dark.aquaLogo.svg(
                  width: 321.0,
                ),
                const SizedBox(height: 80),
                UiAssets.checkSuccess.svg(
                  width: 97.0,
                ),
                const SizedBox(height: 20),
                Text(
                  textAlign: TextAlign.center,
                  context.loc.pinScreenSuccessTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                AquaElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AquaColors.aquaBlue,
                    ),
                    child: Text(context.loc.pinScreenSuccessButton),
                    onPressed: () => context.pop()),
              ])),
        ));
  }
}
