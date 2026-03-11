import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class OutlineContainer extends StatelessWidget {
  const OutlineContainer({
    required this.aquaColors,
    required this.child,
    this.borderColor,
    super.key,
  });

  final AquaColors aquaColors;
  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: aquaColors.surfacePrimary,
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: 1.0,
              )
            : null,
      ),
      child: child,
    );
  }
}
