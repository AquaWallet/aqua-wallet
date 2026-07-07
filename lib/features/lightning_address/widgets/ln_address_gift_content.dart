import 'package:aqua/features/lightning_address/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

import '../pages/gift_box_widget.dart';

class LnAddressGiftContent extends HookWidget {
  const LnAddressGiftContent({
    super.key,
    required this.onOpenBox,
    this.onLater,
  });

  final VoidCallback onOpenBox;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    final floatController = useAnimationController(
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // One full cycle: neutral → up → neutral → down → neutral
    final floatOffset = useAnimation(
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -2.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween(begin: -2.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 2.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 2.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
      ]).animate(floatController),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AquaText.body2Medium(
          text: context.loc.lnAddressGiftSubtitle,
          color: context.aquaColors.textSecondary,
          textAlign: TextAlign.center,
          maxLines: 4,
        ),
        const SizedBox(height: 24),
        AquaCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(
                            color: AquaPrimitiveColors.aquaBlue300,
                          ),
                        ),
                        const Positioned.fill(child: GiftDotsBackground()),
                        Center(
                          child: Hero(
                            tag: 'lnAddressGiftPresent',
                            child: GiftBoxWidget(
                              animated: false,
                              floatOffset: floatOffset,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    YouAquaNetAddress(
                      youColor: context.aquaColors.textSecondary,
                      aquaNetColor: context.aquaColors.accentBrand,
                      style: AquaTypography.h5SemiBold,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        AquaButton.primary(
          text: context.loc.openBox,
          onPressed: () {
            floatController.stop();
            floatController.reset();
            onOpenBox();
          },
        ),
        if (onLater != null) ...[
          const SizedBox(height: 16),
          AquaButton.secondary(
            text: context.loc.later,
            onPressed: onLater,
          ),
        ],
      ],
    );
  }
}
