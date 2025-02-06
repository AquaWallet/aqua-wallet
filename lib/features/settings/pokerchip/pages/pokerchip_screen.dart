import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class PokerchipScreen extends HookConsumerWidget {
  const PokerchipScreen({super.key});

  static const routeName = '/pokerchipScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.bitcoinChip,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 48.0),
        child: Column(children: [
          const Spacer(),
          //ANCHOR - Pokerchip Frame
          SvgPicture.asset(
            darkMode ? Svgs.pokerchipFrameLight : Svgs.pokerchipFrameDark,
            width: 267.0,
            height: 267.0,
          ),
          const SizedBox(height: 42.0),
          //ANCHOR - Title
          Text(
            context.loc.bitcoinChip,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12.0),
          //ANCHOR - Description
          Text(
            context.loc.pokerchipScreenDescription,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
          ),
          const Spacer(flex: 3),
          //ANCHOR: Read Button
          AquaElevatedButton(
            onPressed: () => context.push(PokerchipScannerScreen.routeName),
            child: Text(
              context.loc.pokerchipScreenReadButton,
            ),
          ),
          const SizedBox(height: 16.0),
        ]),
      ),
    );
  }
}
