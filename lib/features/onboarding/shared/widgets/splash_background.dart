import 'package:aqua/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppStyle.backgroundGradient,
      ),
      child: Column(children: [
        const Spacer(flex: 3),
        Container(
          alignment: Alignment.centerRight,
          margin: EdgeInsets.only(left: 28.w),
          //ANCHOR - Background
          child: SvgPicture.asset(Svgs.welcomeBackground,
              height: 540.h,
              colorFilter:
                  const ColorFilter.mode(Color(0xFF018BB2), BlendMode.srcIn)),
        ),
        const Spacer(flex: 8),
      ]),
    );
  }
}
