import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/responsive_utils.dart';
import 'package:flutter_svg/svg.dart';

class MarketplaceButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback? onPressed;

  const MarketplaceButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12.r),
      color: Theme.of(context).colorScheme.onInverseSurface,
      child: Opacity(
        opacity: onPressed != null ? 1 : 0.5,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //ANCHOR - Icon
                SizedBox.square(
                  dimension: context.adaptiveDouble(
                    smallMobile: 48.h,
                    mobile: 52.h,
                    wideMobile: 52.h,
                    tablet: 40.h,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: Theme.of(context).colors.iconBackground,
                    ),
                    child: SvgPicture.asset(
                      icon,
                      height: 18.h,
                      fit: BoxFit.scaleDown,
                      colorFilter: ColorFilter.mode(
                          Theme.of(context).colors.iconForeground,
                          BlendMode.srcIn),
                    ),
                  ),
                ),
                SizedBox(height: 42.h),
                //ANCHOR - Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: context.adaptiveDouble(
                          mobile: 18.sp,
                          wideMobile: 14.sp,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 7.h),
                //ANCHOR - Subtitle
                Expanded(
                  flex: 2,
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: context.adaptiveDouble(
                            mobile: 14.sp,
                            wideMobile: 12.sp,
                          ),
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
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
