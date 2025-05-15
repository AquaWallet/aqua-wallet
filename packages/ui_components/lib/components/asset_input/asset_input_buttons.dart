import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaAssetInputClearButton extends StatelessWidget {
  const AquaAssetInputClearButton({
    super.key,
    this.onTap,
    this.colors,
  });

  final VoidCallback? onTap;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: colors?.surfaceSecondary,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        splashFactory: InkSparkle.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.contains(WidgetState.hovered) &&
              !state.contains(WidgetState.pressed)) {
            return Colors.transparent;
          }
          return null;
        }),
        child: Ink(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: colors?.surfaceSecondary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: AquaIcon.close(
            color: colors?.textTertiary,
            size: 14,
          ),
        ),
      ),
    );
  }
}
