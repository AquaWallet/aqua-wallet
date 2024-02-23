import 'package:aqua/config/config.dart';
import 'package:aqua/config/constants/images.dart' as images;
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashBackground extends HookConsumerWidget {
  const SplashBackground({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final botevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));

    if (botevMode) {
      return LayoutBuilder(
        builder: (_, constraints) => Image.asset(
          images.botevSplash,
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: AppStyle.backgroundGradient,
      ),
      child: Column(children: [
        const Spacer(flex: 3),
        Container(
          alignment: Alignment.centerRight,
          margin: EdgeInsets.only(left: 28.w),
          //ANCHOR - Background
          child: SvgPicture.asset(
            Svgs.welcomeBackground,
            height: 540.h,
            colorFilter: const ColorFilter.mode(
              Color(0xFF018BB2),
              BlendMode.srcIn,
            ),
          ),
        ),
        const Spacer(flex: 8),
      ]),
    );
  }
}
