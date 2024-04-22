import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/config/constants/svgs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

const _socials = {
  constants.aquaWebsiteUrl: Svgs.website,
  constants.aquaTwitterUrl: Svgs.twitter,
  constants.aquaInstagramUrl: Svgs.instagram,
};

class SettingsSocialLinks extends StatelessWidget {
  const SettingsSocialLinks({
    super.key,
    required this.onLinkClick,
  });

  final Function(String) onLinkClick;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      alignment: Alignment.center,
      margin: EdgeInsets.only(left: 10.w, right: 8.w),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        primary: false,
        padding: EdgeInsets.only(right: 8.w),
        itemCount: _socials.length,
        separatorBuilder: (_, __) => SizedBox(width: 30.w),
        itemBuilder: (context, index) => Center(
          child: InkWell(
            onTap: () => onLinkClick(_socials.keys.elementAt(index)),
            child: SvgPicture.asset(
              _socials.values.elementAt(index),
              width: 24.r,
              height: 24.r,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onBackground,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
