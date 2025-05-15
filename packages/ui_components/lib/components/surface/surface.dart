import 'package:flutter/material.dart';

class AquaCard extends StatelessWidget {
  const AquaCard({
    super.key,
    this.width,
    this.height,
    this.onTap,
    this.color,
    this.child,
    this.borderRadius,
    this.elevation = 0,
  }) : glassEffect = false;

  const AquaCard.surface({
    super.key,
    this.width,
    this.height,
    this.onTap,
    this.color,
    this.child,
    this.borderRadius,
    required this.elevation,
  }) : glassEffect = false;

  const AquaCard.glass({
    super.key,
    this.width,
    this.height,
    this.onTap,
    this.borderRadius,
    this.color,
    this.child,
    this.elevation = 4,
  }) : glassEffect = true;

  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Widget? child;
  final Color? color;
  final double elevation;
  final bool glassEffect;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Ink(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: glassEffect && color == null
            ? Theme.of(context).colorScheme.surface
            : color,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        shadowColor: glassEffect ? color?.withAlpha(125) : null,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: color?.withAlpha(25) ??
              Theme.of(context).colorScheme.surface.withAlpha(25),
          borderRadius: borderRadius ?? BorderRadius.circular(4),
          child: child,
        ),
      ),
    );
  }
}
