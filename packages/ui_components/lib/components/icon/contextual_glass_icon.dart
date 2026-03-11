import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaContextualGlassIcon extends StatelessWidget {
  const AquaContextualGlassIcon({
    super.key,
    required this.icon,
    this.size = 48,
    this.backgroundColor,
    this.onTap,
  });

  final AquaIcon icon;
  final double size;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AquaColors.lightColors.glassSurface,
          borderRadius: BorderRadius.circular(100),
        ),
        child: icon,
      ),
    );
  }
}
