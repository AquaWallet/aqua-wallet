import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

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
    final background = switch (null) {
      _ when glassEffect && color == null =>
        Theme.of(context).brightness == Brightness.dark
            ? AquaColors.darkColors.glassSurface
            : AquaColors.lightColors.glassSurface,
      _ when color == null => Theme.of(context).colorScheme.surface,
      _ => color,
    };
    return Ink(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: AquaPrimitiveColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: background,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        shadowColor: glassEffect ? color?.withAlpha(125) : null,
        child: InkWell(
          onTap: onTap,
          splashFactory: InkRipple.splashFactory,
          highlightColor: color?.withAlpha(25) ??
              Theme.of(context).colorScheme.surface.withAlpha(25),
          borderRadius: borderRadius ?? BorderRadius.circular(4),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(4),
            child: child,
          ),
        ),
      ),
    );
  }
}
