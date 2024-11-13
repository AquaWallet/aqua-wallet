import 'package:aqua/gen/assets.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
              color: context.colors.bottomNavBarBorder,
              width: 1.h,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, -4),
              blurRadius: 10,
              spreadRadius: 4,
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 53.w,
          right: 53.w,
          bottom: 20.h,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CustomBottomNavigationBarItem(
              icon: UiAssets.svgs.walletFooterWallet,
              label: context.loc.homeTabWalletTitle,
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            const Spacer(),
            _CustomBottomNavigationBarItem(
              icon: UiAssets.svgs.walletFooterMarketplace,
              label: context.loc.homeTabMarketplaceTitle,
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const Spacer(),
            _CustomBottomNavigationBarItem(
              icon: UiAssets.svgs.walletFooterSettings,
              label: context.loc.homeTabSettingsTitle,
              selected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBottomNavigationBarItem extends StatelessWidget {
  const _CustomBottomNavigationBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final SvgGenImage icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon.svg(
            width: 40.r,
            height: 40.r,
            colorFilter: ColorFilter.mode(
              selected
                  ? context.colors.bottomNavBarIconSelected
                  : context.colors.bottomNavBarIconUnselected,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: selected
                  ? context.colors.bottomNavBarIconSelected
                  : context.colors.bottomNavBarIconUnselected,
            ),
          ),
        ],
      ),
    );
  }
}
