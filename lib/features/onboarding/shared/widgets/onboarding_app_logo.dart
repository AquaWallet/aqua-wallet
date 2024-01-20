import 'package:aqua/config/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingAppLogo extends StatelessWidget {
  const OnboardingAppLogo({
    super.key,
    this.onTap,
    this.onLongPress,
    required this.description,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //ANCHOR - Logo
        GestureDetector(
          onTap: kDebugMode ? onTap : null,
          onLongPress: kDebugMode ? onLongPress : null,
          child: SvgPicture.asset(
            Svgs.aquaLogo,
            height: 60.h,
          ),
        ),
        SizedBox(height: 30.h),
        //ANCHOR - Description
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                height: 1.5,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
        ),
      ],
    );
  }
}
