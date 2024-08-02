import 'package:aqua/common/widgets/confirmation_slider.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
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
        width: MediaQuery.sizeOf(context).width - 56.w,
        height: 52.h,
        stickToEnd: true,
        backgroundShape: BorderRadius.circular(12.r),
        backgroundColor: Theme.of(context).colorScheme.background,
        disabledBackgroundColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(.3),
        text: context.loc.exchangeSwapButton,
        textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: enabled
                ? Theme.of(context).colorScheme.onBackground
                : Theme.of(context).colorScheme.onPrimary),
        onConfirmation: () {
          if (enabled) {
            onConfirm.call();
          }
        },
        sliderWidth: 74.w,
        sliderHeight: 52.h,
        sliderButtonContent: Container(
          width: 74.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            borderRadius: BorderRadius.all(Radius.circular(12.r)),
          ),
          child: SvgPicture.asset(
            Svgs.slideConfirmArrow,
            width: 15.r,
            height: 15.r,
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
            borderRadius: BorderRadius.all(Radius.circular(12.r)),
          ),
        ),
      ),
    );
  }
}
