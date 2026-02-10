import 'package:aqua/config/constants/animations.dart';
import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';
import 'package:ui_components/ui_components.dart';

class LoaderScreenWidget extends HookWidget {
  const LoaderScreenWidget({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final aquaColors = context.aquaColors;

    ///This is just for mocking all design screens and functionality
    useEffect(() {
      Future.delayed(const Duration(seconds: 3), () => Navigator.pop(context));
      return null;
    }, []);

    return Material(
      color: aquaColors.surfaceBackground,
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: SizedBox(
          width: onboardingContentWidth,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UiAssets.svgs.aquaLogoColorSpaced.svg(
                height: 30,
                color: aquaColors.textPrimary,
              ),
              Column(
                children: [
                  Lottie.asset(
                    transactionProcessing,
                    repeat: true,
                    frameRate: const FrameRate(120),
                    fit: BoxFit.contain,
                    height: heightOfLoadingLottie,
                  ),
                  AquaText.h3Medium(
                    text: '${context.loc.commonJustAMoment}...',
                    color: aquaColors.textPrimary,
                  ),
                  const SizedBox(height: 10),
                  AquaText.subtitle(
                    text: message,
                    color: aquaColors.textSecondary,
                    maxLines: 3,
                  )
                ],
              ),
              const AquaText.caption1(text: 'App Version 0.2.7 (160)'),
            ],
          ),
        ),
      ),
    );
  }
}
