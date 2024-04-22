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
        title: context.loc.pokerchipScreenTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
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
            context.loc.pokerchipScreenLabel,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 12.h),
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
            onPressed: () => Navigator.of(context)
                .pushNamed(PokerchipScannerScreen.routeName),
            child: Text(
              context.loc.pokerchipScreenReadButton,
            ),
          ),
          SizedBox(height: 16.h),
        ]),
      ),
    );
  }
}
