import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BoxShadowCard extends Card {
  const BoxShadowCard({
    Color? color,
    Color? shadowColor,
    Color? surfaceTintColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    EdgeInsetsGeometry? margin,
    Widget? child,
    super.key,
    bool borderOnForeground = true,
    bool semanticContainer = true,
    this.bordered = true,
    this.borderColor,
    this.error = false,
    this.borderRadius,
    this.borderWidth,
  }) : super(
          color: color,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          elevation: elevation,
          shape: shape,
          borderOnForeground: borderOnForeground,
          margin: margin,
          clipBehavior: clipBehavior,
          child: child,
          semanticContainer: semanticContainer,
        );

  final BorderRadius? borderRadius;
  final bool error;
  final bool bordered;
  final Color? borderColor;
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: bordered
            ? Border.all(
                color: error
                    ? Theme.of(context).colorScheme.error
                    : borderColor ?? Colors.transparent,
                width: borderWidth ?? 2.r,
              )
            : null,
      ),
      child: super.child,
    );
  }
}
