import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletTabHeaderButton extends StatelessWidget {
  const WalletTabHeaderButton({
    Key? key,
    required this.svgAssetName,
    required this.label,
    this.radius,
    required this.onPressed,
    this.isDark = false,
    this.backgroundColor,
  }) : super(key: key);

  final BorderRadius? radius;
  final String svgAssetName;
  final String label;
  final VoidCallback onPressed;
  final bool isDark;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.maxFinite,
      child: Material(
        borderRadius: radius,
        color:
            backgroundColor ?? Colors.transparent.withOpacity(isDark ? .05 : 0),
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Ink(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //ANCHOR - Icon
                SvgPicture.asset(svgAssetName,
                    width: 16.w,
                    height: 16.w,
                    fit: BoxFit.scaleDown,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onBackground,
                        BlendMode.srcIn)),
                SizedBox(width: 12.w),
                //ANCHOR - Label
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
