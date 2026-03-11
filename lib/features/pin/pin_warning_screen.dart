import 'package:aqua/features/pin/pin_screen.dart';
import 'package:aqua/features/recovery/pages/warning_phrase_screen.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class PinWarningScreen extends HookConsumerWidget {
  static const routeName = '/setupWarningPin';

  const PinWarningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        backgroundColor: context.aquaColors.glassInverse.withOpacity(0.5),
        body: SafeArea(
          child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AquaModalSheet(
                    copiedToClipboardText: context.loc.copiedToClipboard,
                    title: context.loc.pinScreenWarningTitle,
                    message: context.loc.pinScreenWarningDescription,
                    primaryButtonText: context.loc.pinScreenWarningViewRecovery,
                    iconVariant: AquaRingedIconVariant.warning,
                    icon: AquaIcon.warning(color: Colors.white),
                    onPrimaryButtonTap: () =>
                        context.push(WalletPhraseWarningScreen.routeName),
                    secondaryButtonText: context.loc.pinScreenSavedSeed,
                    onSecondaryButtonTap: () =>
                        context.replace(SetupPinScreen.routeName),
                    colors: context.aquaColors),
                const SizedBox(height: 30),
              ]),
        ));
  }
}
