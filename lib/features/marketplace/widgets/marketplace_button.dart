import 'package:aqua/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      // TODO: Setup color in Aqua/App colors
      color: Theme.of(context).colorScheme.onInverseSurface,
      child: Opacity(
        opacity: onPressed != null ? 1 : 0.5,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(height: 26.h),
                //ANCHOR - Icon
                SizedBox.square(
                  dimension: 52.w,
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
                const Spacer(),
                //ANCHOR - Title
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 20.sp),
                ),
                SizedBox(height: 4.h),
                //ANCHOR - Subtitle
                Text(
                  subtitle,
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
