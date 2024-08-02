import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletTabHeaderButton extends StatelessWidget {
  const WalletTabHeaderButton({
    super.key,
    required this.svgAssetName,
    required this.label,
    this.radius,
    required this.onPressed,
    this.isDark = false,
  });

  final BorderRadius? radius;
  final String svgAssetName;
  final String label;
  final VoidCallback onPressed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.maxFinite,
      child: Material(
        borderRadius: radius,
        color: Colors.transparent.withOpacity(isDark ? .05 : 0),
        child: InkWell(
          onTap: onPressed,
          splashColor: Theme.of(context).colors.walletTabButtonBackgroundColor,
          borderRadius: radius,
          child: Ink(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //ANCHOR - Icon
                SvgPicture.asset(
                  svgAssetName,
                  width: 16.w,
                  height: 16.w,
                  fit: BoxFit.scaleDown,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onPrimaryContainer,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 12.w),
                //ANCHOR - Label
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
