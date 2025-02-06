import 'package:aqua/common/widgets/confirmation_slider.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SwapSlider extends ConsumerWidget {
  const SwapSlider({super.key, required this.onConfirm});

  final void Function() onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(swapLoadingIndicatorStateProvider);
    final enabled = state != const SwapProgressState.connecting();

    return BoxShadowContainer(
      color: Colors.transparent,
      child: ConfirmationSlider(
        enabled: enabled,
        width: MediaQuery.sizeOf(context).width - 56.0,
        height: 52.0,
        stickToEnd: true,
        backgroundShape: BorderRadius.circular(12.0),
        backgroundColor: Theme.of(context).colors.background,
        disabledBackgroundColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(.3),
        text: context.loc.swap,
        textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: enabled
                ? Theme.of(context).colors.onBackground
                : Theme.of(context).colorScheme.onPrimary),
        onConfirmation: () {
          if (enabled) {
            onConfirm.call();
          }
        },
        sliderWidth: 74.0,
        sliderHeight: 52.0,
        sliderButtonContent: Container(
          width: 74.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          ),
          child: SvgPicture.asset(
            Svgs.slideConfirmArrow,
            width: 15.0,
            height: 15.0,
            fit: BoxFit.scaleDown,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
        backgroundEndContent: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          ),
        ),
      ),
    );
  }
}
