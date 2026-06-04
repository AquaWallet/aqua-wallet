import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

enum AquaRingedIconVariant {
  /// Outer: surfaceTertiary. Inner ring: surfaceSecondary. Neutral, low emphasis.
  normal,

  /// Outer: accentSuccessTransparent. Inner: accentSuccess.
  success,

  /// Outer: accentDangerTransparent. Inner: accentDanger.
  danger,

  /// Outer: accentWarningTransparent. Inner: accentWarning.
  warning,

  /// Outer: accentBrandTransparent. Inner: accentBrand.
  info,

  /// Outer: aquaBlue16. Inner: aquaBlue500. Primary brand accent.
  accent,
}

class AquaRingedIcon extends StatelessWidget {
  const AquaRingedIcon({
    super.key,
    required this.icon,
    required this.variant,
    required this.colors,
    this.backgroundColor,
    this.ringColor,
  });

  final Widget icon;
  final AquaRingedIconVariant variant;
  final AquaColors colors;

  /// When set, overrides the variant's outer background color.
  final Color? backgroundColor;

  /// When set, overrides the variant's inner ring color.
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final outerColor = backgroundColor ?? _outerColor(variant, colors);
    final innerColor = ringColor ?? _innerColor(variant, colors);

    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: outerColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: innerColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: icon,
      ),
    );
  }

  static Color _outerColor(AquaRingedIconVariant variant, AquaColors colors) =>
      switch (variant) {
        AquaRingedIconVariant.normal => colors.surfaceTertiary,
        AquaRingedIconVariant.success => colors.accentSuccessTransparent,
        AquaRingedIconVariant.danger => colors.accentDangerTransparent,
        AquaRingedIconVariant.warning => colors.accentWarningTransparent,
        AquaRingedIconVariant.info => colors.accentBrandTransparent,
        AquaRingedIconVariant.accent => AquaPrimitiveColors.aquaBlue16,
      };

  static Color _innerColor(AquaRingedIconVariant variant, AquaColors colors) =>
      switch (variant) {
        AquaRingedIconVariant.normal => colors.surfaceSecondary,
        AquaRingedIconVariant.success => colors.accentSuccess,
        AquaRingedIconVariant.danger => colors.accentDanger,
        AquaRingedIconVariant.warning => colors.accentWarning,
        AquaRingedIconVariant.info => colors.accentBrand,
        AquaRingedIconVariant.accent => AquaPrimitiveColors.aquaBlue500,
      };
}
