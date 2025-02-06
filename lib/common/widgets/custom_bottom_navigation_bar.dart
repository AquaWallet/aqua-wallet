import 'package:aqua/gen/assets.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:aqua/common/keys/common_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
        height: 115,
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: context.colors.bottomNavBarBorder,
              width: 1,
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
        padding: const EdgeInsets.only(
          left: 53,
          right: 53,
          bottom: 20,
          top: 20,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CustomBottomNavigationBarItem(
              key: CommonKeys.walletButton,
              icon: UiAssets.svgs.walletFooterWallet,
              label: context.loc.homeTabWalletTitle,
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            const Spacer(),
            _CustomBottomNavigationBarItem(
              key: CommonKeys.marketplaceButton,
              icon: UiAssets.svgs.walletFooterMarketplace,
              label: context.loc.marketplaceTitle,
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const Spacer(),
            _CustomBottomNavigationBarItem(
              key: CommonKeys.settingsButton,
              icon: UiAssets.svgs.walletFooterSettings,
              label: context.loc.settings,
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
    super.key,
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
            width: context.adaptiveDouble(smallMobile: 32, mobile: 40),
            height: context.adaptiveDouble(smallMobile: 32, mobile: 40),
            colorFilter: ColorFilter.mode(
              selected
                  ? context.colors.bottomNavBarIconSelected
                  : context.colors.bottomNavBarIconUnselected,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              letterSpacing: .0,
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
