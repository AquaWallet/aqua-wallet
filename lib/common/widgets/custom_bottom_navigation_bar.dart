import 'package:aqua/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavigationBar extends StatelessWidget {
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
      child: SizedBox(
        height: 115.h,
        child: _CustomBottomNavigationBar.create(
          context: context,
          currentIndex: currentIndex,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _CustomBottomNavigationBar extends BottomNavigationBar {
  _CustomBottomNavigationBar._(
    BuildContext context, {
    required List<BottomNavigationBarItem> items,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) : super(
          items: items,
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedFontSize: 11.sp,
          unselectedFontSize: 11.sp,
        );

  factory _CustomBottomNavigationBar.create({
    required BuildContext context,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return _CustomBottomNavigationBar._(
      context,
      currentIndex: currentIndex,
      items: <BottomNavigationBarItem>[
        _CustomBottomNavigationBarItem.withSvgAssetIcon(
          context: context,
          svgAssetName: Svgs.tabWallet,
          label: AppLocalizations.of(context)!.homeTabWalletTitle,
          width: 22.r,
          height: 20.r,
          selected: currentIndex == 0,
        ),
        _CustomBottomNavigationBarItem.withSvgAssetIcon(
          context: context,
          svgAssetName: Svgs.tabMarketplace,
          label: AppLocalizations.of(context)!.homeTabMarketplaceTitle,
          width: 20.r,
          height: 24.r,
          selected: currentIndex == 1,
        ),
        _CustomBottomNavigationBarItem.withSvgAssetIcon(
          context: context,
          svgAssetName: Svgs.tabSettings,
          label: AppLocalizations.of(context)!.homeTabSettingsTitle,
          width: 22.r,
          height: 22.r,
          selected: currentIndex == 2,
        ),
      ],
      onTap: onTap,
    );
  }
}

class _CustomBottomNavigationBarItem extends BottomNavigationBarItem {
  _CustomBottomNavigationBarItem(
    BuildContext context, {
    required String svgAssetName,
    required String label,
    required double width,
    required double height,
    required bool selected,
  }) : super(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: SizedBox(
              width: 38.r,
              height: 38.r,
              child: Center(
                child: SvgPicture.asset(
                  svgAssetName,
                  width: width,
                  height: height,
                  colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .bottomNavigationBarTheme
                          .unselectedItemColor!,
                      BlendMode.srcIn),
                ),
              ),
            ),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Container(
              width: 38.r,
              height: 38.r,
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: Theme.of(context).colors.iconBackground,
                borderRadius: BorderRadius.circular(100.r),
              ),
              child: Center(
                child: SvgPicture.asset(svgAssetName,
                    width: width,
                    height: height,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colors.iconForeground,
                        BlendMode.srcIn)),
              ),
            ),
          ),
          label: label,
        );

  factory _CustomBottomNavigationBarItem.withSvgAssetIcon({
    required BuildContext context,
    required String svgAssetName,
    required String label,
    required double width,
    required double height,
    required bool selected,
  }) {
    return _CustomBottomNavigationBarItem(
      context,
      svgAssetName: svgAssetName,
      label: label,
      width: width,
      height: height,
      selected: selected,
    );
  }
}
