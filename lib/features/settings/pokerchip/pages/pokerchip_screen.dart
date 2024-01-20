import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
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
        title: AppLocalizations.of(context)!.pokerchipScreenTitle,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 48.h),
        child: Column(children: [
          const Spacer(),
          //ANCHOR - Pokerchip Frame
          SvgPicture.asset(
            darkMode ? Svgs.pokerchipFrameLight : Svgs.pokerchipFrameDark,
            width: 267.r,
            height: 267.r,
          ),
          SizedBox(height: 42.h),
          //ANCHOR - Title
          Text(
            AppLocalizations.of(context)!.pokerchipScreenLabel,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 12.h),
          //ANCHOR - Description
          Text(
            AppLocalizations.of(context)!.pokerchipScreenDescription,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
          ),
          const Spacer(flex: 3),
          //ANCHOR: Read Button
          AquaElevatedButton(
            onPressed: () => Navigator.of(context)
                .pushNamed(PokerchipScannerScreen.routeName),
            child: Text(
              AppLocalizations.of(context)!.pokerchipScreenReadButton,
            ),
          ),
          SizedBox(height: 16.h),
        ]),
      ),
    );
  }
}
