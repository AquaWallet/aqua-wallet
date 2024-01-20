import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';

class PokerchipScanViewButton extends StatelessWidget {
  const PokerchipScanViewButton({
    super.key,
    required this.iconSvg,
    required this.label,
    required this.onPressed,
  });

  final String iconSvg;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12.r),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          height: 52.h,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconSvg,
                width: 16.w,
                height: 16.w,
                fit: BoxFit.scaleDown,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onBackground,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
