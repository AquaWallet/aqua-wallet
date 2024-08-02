import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BoxShadowCard extends Card {
  const BoxShadowCard({
    super.color,
    super.shadowColor,
    super.surfaceTintColor,
    super.elevation,
    super.shape,
    super.clipBehavior,
    super.margin,
    super.child,
    super.key,
    super.borderOnForeground,
    super.semanticContainer,
    this.bordered = true,
    this.borderColor,
    this.error = false,
    this.borderRadius,
    this.borderWidth,
  });

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
