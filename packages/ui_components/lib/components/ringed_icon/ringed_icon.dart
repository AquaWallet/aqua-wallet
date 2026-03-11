import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

enum AquaRingedIconVariant {
  normal,
  success,
  danger,
  warning,
  info,
}

class AquaRingedIcon extends StatelessWidget {
  const AquaRingedIcon({
    super.key,
    required this.icon,
    required this.variant,
    required this.colors,
  });

  final Widget icon;
  final AquaRingedIconVariant variant;
  final AquaColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: switch (variant) {
          AquaRingedIconVariant.normal => colors.surfaceTertiary,
          AquaRingedIconVariant.success => colors.accentSuccessTransparent,
          AquaRingedIconVariant.danger => colors.accentDangerTransparent,
          AquaRingedIconVariant.warning => colors.accentWarningTransparent,
          AquaRingedIconVariant.info => colors.accentBrandTransparent,
        },
        borderRadius: BorderRadius.circular(100),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: switch (variant) {
            AquaRingedIconVariant.normal => colors.surfaceSecondary,
            AquaRingedIconVariant.success => colors.accentSuccess,
            AquaRingedIconVariant.danger => colors.accentDanger,
            AquaRingedIconVariant.warning => colors.accentWarning,
            AquaRingedIconVariant.info => colors.accentBrand,
          },
          borderRadius: BorderRadius.circular(100),
        ),
        child: icon,
      ),
    );
  }
}
