import 'package:aqua/common/widgets/confirmation_slider.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';

class SendAssetConfirmSlider extends StatelessWidget {
  const SendAssetConfirmSlider({
    super.key,
    required this.onConfirm,
    required this.enabled,
    required this.text,
  });

  final VoidCallback onConfirm;
  final bool enabled;
  final String text;

  @override
  Widget build(BuildContext context) {
    return BoxShadowContainer(
      child: ConfirmationSlider(
        enabled: enabled,
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
          child: SvgPicture.asset(
            Svgs.slideConfirmArrow,
            width: 15.r,
            height: 15.r,
            fit: BoxFit.scaleDown,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
