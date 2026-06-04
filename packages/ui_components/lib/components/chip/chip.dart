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
    this.leadingIcon,
    this.trailingIcon,
    this.compact = false,
    this.colors,
    this.onTap,
  }) : variant = AquaChipVariant.normal;

  const AquaChip.success({
    super.key,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.compact = false,
    this.colors,
    this.onTap,
  }) : variant = AquaChipVariant.success;

  const AquaChip.error({
    super.key,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.compact = false,
    this.colors,
    this.onTap,
  }) : variant = AquaChipVariant.error;

  const AquaChip.accent({
    super.key,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.compact = false,
    this.colors,
    this.onTap,
  }) : variant = AquaChipVariant.accent;

  final String label;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool compact;
  final AquaChipVariant variant;
  final AquaColors? colors;
  final VoidCallback? onTap;

  EdgeInsetsGeometry _buildPadding() {
    final hasLeading = leadingIcon != null;
    final hasTrailing = trailingIcon != null;

    if (!hasLeading && !hasTrailing) {
      return EdgeInsets.symmetric(
        horizontal: compact ? 8 : 16,
        vertical: 4,
      );
    }

    return EdgeInsetsDirectional.only(
      start: hasLeading ? (compact ? 4 : 8) : (compact ? 8 : 16),
      end: hasTrailing ? (compact ? 4 : 8) : (compact ? 8 : 16),
      top: 4,
      bottom: 4,
    );
  }

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
        onTap: onTap != null
            ? () => WidgetsBinding.instance
                .addPostFrameCallback((_) => onTap?.call())
            : null,
        borderRadius: BorderRadius.circular(32),
        splashFactory: InkRipple.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith(
          (state) => state.isHovered ? Colors.transparent : null,
        ),
        child: Container(
          padding: _buildPadding(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                leadingIcon!,
                SizedBox(width: compact ? 4 : 6),
              ],
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
              if (trailingIcon != null) ...[
                SizedBox(width: compact ? 4 : 6),
                trailingIcon!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
