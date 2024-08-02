import 'package:aqua/common/widgets/confirmation_slider.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

enum SliderState { initial, inProgress, completed, error }

class SendAssetConfirmSlider extends HookConsumerWidget {
  const SendAssetConfirmSlider({
    super.key,
    required this.onConfirm,
    required this.enabled,
    required this.text,
    required this.sliderState,
  });

  final Future<void> Function() onConfirm;
  final bool enabled;
  final String text;
  final SliderState sliderState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sliderKey = useState(UniqueKey());

    useEffect(() {
      if (sliderState == SliderState.initial) {
        sliderKey.value = UniqueKey();
      }
      return null;
    }, [sliderState]);

    return BoxShadowContainer(
      child: ConfirmationSlider(
        key: sliderKey.value,
        enabled: enabled && sliderState == SliderState.initial,
        width: MediaQuery.sizeOf(context).width - 56.w,
        height: 52.h,
        stickToEnd: true,
        backgroundShape: BorderRadius.circular(12.r),
        backgroundColor: Theme.of(context).colorScheme.background,
        text: text,
        textStyle: Theme.of(context).textTheme.titleSmall,
        onConfirmation: onConfirm,
        sliderWidth: 74.w,
        sliderHeight: 52.h,
        sliderButtonContent: Container(
          width: 74.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.all(Radius.circular(12.r)),
          ),
          child: _buildSliderContent(context, sliderState),
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

  Widget _buildSliderContent(BuildContext context, SliderState state) {
    switch (state) {
      case SliderState.initial:
        return SvgPicture.asset(
          Svgs.slideConfirmArrow,
          width: 15.r,
          height: 15.r,
          fit: BoxFit.scaleDown,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        );
      case SliderState.inProgress:
        return Center(
          child: SizedBox(
            width: 26.r,
            height: 26.r,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3.0,
            ),
          ),
        );
      case SliderState.completed:
        return Icon(Icons.check, color: Colors.white, size: 26.r);
      case SliderState.error:
        return Icon(Icons.error, color: Colors.white, size: 26.r);
    }
  }
}
