import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

enum AquaChipVariant {
  normal,
  success,
  error,
  accent,
}

class AquaChip extends StatelessWidget {
  const AquaChip({
    super.key,
    required this.label,
    this.icon,
    this.compact = false,
    this.colors,
    this.onTap,
  }) : variant = AquaChipVariant.normal;

  const AquaChip.success({
    super.key,
    required this.label,
    this.icon,
    this.compact = false,
    this.colors,
    this.onTap,
  }) : variant = AquaChipVariant.success;

  const AquaChip.error({
    super.key,
    required this.label,
    this.icon,
    this.compact = false,
    this.colors,
    this.onTap,
  }) : variant = AquaChipVariant.error;

  const AquaChip.accent({
    super.key,
    required this.label,
    this.icon,
    this.compact = false,
    this.colors,
    this.onTap,
  }) : variant = AquaChipVariant.accent;

  final String label;
  final Widget? icon;
  final bool compact;
  final AquaChipVariant variant;
  final AquaColors? colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (variant) {
          AquaChipVariant.success => colors?.chipSuccessBackgroundColor,
          AquaChipVariant.error => colors?.chipErrorBackgroundColor,
          AquaChipVariant.accent =>
            Theme.of(context).colorScheme.primary.withOpacity(0.16),
          _ => Theme.of(context).colorScheme.surface,
        } ??
        Theme.of(context).colorScheme.surface;
    final foregroundColor = switch (variant) {
          AquaChipVariant.success => colors?.chipSuccessForegroundColor,
          AquaChipVariant.error => colors?.chipErrorForegroundColor,
          AquaChipVariant.accent => Theme.of(context).colorScheme.primary,
          _ => Theme.of(context).colorScheme.onSurface,
        } ??
        Theme.of(context).colorScheme.onSurface;

    return Card(
      color: backgroundColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      elevation: variant == AquaChipVariant.normal ? 8 : 0,
      shadowColor: variant == AquaChipVariant.normal ? Colors.black26 : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith(
          (state) => state.isHovered ? Colors.transparent : null,
        ),
        child: Container(
          padding: icon == null
              ? EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 16,
                  vertical: 4,
                )
              : EdgeInsetsDirectional.only(
                  start: compact ? 8 : 16,
                  end: compact ? 4 : 8,
                  top: 4,
                  bottom: 4,
                ),
          child: Row(
            children: [
              Text(
                label,
                style: compact
                    ? AquaTypography.caption1SemiBold.copyWith(
                        color: foregroundColor,
                      )
                    : AquaTypography.body2SemiBold.copyWith(
                        color: foregroundColor,
                      ),
              ),
              if (icon != null) ...{
                Container(
                  margin: const EdgeInsetsDirectional.only(start: 4),
                  child: icon!,
                ),
              }
            ],
          ),
        ),
      ),
    );
  }
}
