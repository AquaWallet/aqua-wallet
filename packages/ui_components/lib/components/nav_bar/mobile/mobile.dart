import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

const _kMobileNavBarHeight = 93.0;

typedef AquaNavBarItemBuilder = AquaNavBarItem Function(
  BuildContext context,
  int index,
);

class AquaNavBar extends HookWidget implements PreferredSizeWidget {
  const AquaNavBar({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.colors,
  });

  final int itemCount;
  final AquaNavBarItemBuilder itemBuilder;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: colors?.glassBackground.withOpacity(0.7),
          height: _kMobileNavBarHeight,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(
              itemCount,
              (index) => Expanded(
                child: itemBuilder(context, index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_kMobileNavBarHeight);
}

typedef AquaNavBarNavItemIcon = Function({
  Color? color,
  Key? key,
  EdgeInsets? padding,
  double size,
});

class AquaNavBarItem extends StatelessWidget {
  const AquaNavBarItem({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected,
    this.colors,
    this.onTap,
  });

  final String label;
  final AquaNavBarNavItemIcon icon;
  final bool? isSelected;
  final VoidCallback? onTap;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    final isSelectedState = (isSelected == null || isSelected == true);
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.resolveWith((state) {
        if (isSelected == null && state.isPressed) {
          return null;
        }
        return Colors.transparent;
      }),
      child: Ink(
        padding: EdgeInsets.only(bottom: 21),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon(
              size: 24,
              color:
                  isSelectedState ? colors?.textPrimary : colors?.textTertiary,
            ),
            const SizedBox(height: 4),
            AquaText.caption2SemiBold(
              text: label,
              color:
                  isSelectedState ? colors?.textPrimary : colors?.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
