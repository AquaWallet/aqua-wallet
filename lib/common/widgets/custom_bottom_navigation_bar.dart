import 'package:aqua/config/config.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavigationBar extends HookWidget {
  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        height: 115.h,
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colors.bottomNavBarBorder,
              width: 1.h,
            ),
          ),
        ),
        padding: EdgeInsets.only(
          left: 12.w,
          right: 12.w,
          bottom: 12.h,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _CustomBottomNavigationBarItem(
                svgAssetName: Svgs.tabWallet,
                label: context.loc.homeTabWalletTitle,
                iconWidth: 22.r,
                iconHeight: 20.r,
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
            ),
            Expanded(
              child: _CustomBottomNavigationBarItem(
                svgAssetName: Svgs.tabMarketplace,
                label: context.loc.homeTabMarketplaceTitle,
                iconWidth: 20.r,
                iconHeight: 24.r,
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ),
            Expanded(
              child: _CustomBottomNavigationBarItem(
                svgAssetName: Svgs.tabSettings,
                label: context.loc.homeTabSettingsTitle,
                iconWidth: 22.r,
                iconHeight: 22.r,
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBottomNavigationBarItem extends StatelessWidget {
  const _CustomBottomNavigationBarItem({
    required this.svgAssetName,
    required this.label,
    required this.selected,
    required this.iconWidth,
    required this.iconHeight,
    required this.onTap,
  });

  final String svgAssetName;
  final String label;
  final bool selected;
  final double iconWidth;
  final double iconHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            padding: selected ? EdgeInsets.all(10.r) : EdgeInsets.zero,
            decoration: selected
                ? BoxDecoration(
                    color: Theme.of(context).colors.iconBackground,
                    borderRadius: BorderRadius.circular(100.r),
                  )
                : null,
            child: Center(
              child: SvgPicture.asset(
                svgAssetName,
                width: iconWidth,
                height: iconHeight,
                colorFilter: ColorFilter.mode(
                  selected
                      ? Theme.of(context).colors.iconForeground
                      : Theme.of(context)
                          .bottomNavigationBarTheme
                          .unselectedItemColor!,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: selected
                ? Theme.of(context)
                    .bottomNavigationBarTheme
                    .selectedLabelStyle
                    ?.copyWith(fontSize: 11.sp)
                : Theme.of(context)
                    .bottomNavigationBarTheme
                    .unselectedLabelStyle
                    ?.copyWith(fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}
