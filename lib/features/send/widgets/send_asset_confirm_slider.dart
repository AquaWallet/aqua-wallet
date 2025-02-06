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

    return ConfirmationSlider(
      key: sliderKey.value,
      enabled: enabled && sliderState == SliderState.initial,
      width: MediaQuery.sizeOf(context).width - 56,
      height: 52,
      stickToEnd: true,
      backgroundShape: BorderRadius.circular(9),
      backgroundColor: Theme.of(context).colors.altScreenSurface,
      text: text,
      textStyle: Theme.of(context).textTheme.titleMedium,
      onConfirmation: onConfirm,
      sliderWidth: 75,
      sliderHeight: 50,
      sliderButtonContent: Container(
        width: 74,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.all(Radius.circular(9)),
        ),
        child: _buildSliderContent(context, sliderState),
      ),
      backgroundEndContent: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          borderRadius: const BorderRadius.all(Radius.circular(9)),
        ),
      ),
    );
  }

  Widget _buildSliderContent(BuildContext context, SliderState state) {
    switch (state) {
      case SliderState.initial:
        return SvgPicture.asset(
          Svgs.slideConfirmArrow,
          width: 15,
          height: 15,
          fit: BoxFit.scaleDown,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        );
      case SliderState.inProgress:
        return const Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        );
      case SliderState.completed:
        return const Icon(Icons.check, color: Colors.white, size: 26);
      case SliderState.error:
        return const Icon(Icons.error, color: Colors.white, size: 26);
    }
  }
}
