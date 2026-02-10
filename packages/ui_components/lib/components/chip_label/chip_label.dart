import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

enum AquaChipLabelVariant {
  normal,
  success,
  warning,
  error,
}

enum AquaChipLabelPointerPosition {
  none,
  top,
  bottom,
}

class AquaChipLabel extends StatelessWidget {
  const AquaChipLabel({
    super.key,
    required this.message,
    this.onLeadingIconTap,
    this.onTrailingIconTap,
    this.isDismissible = false,
    this.isInfo = false,
    this.leadingIcon,
    this.margin = const EdgeInsets.all(16),
    this.trailingIcon,
    this.variant = AquaChipLabelVariant.normal,
    this.pointerPosition = AquaChipLabelPointerPosition.none,
    this.pointerSize = kDefaultLabelPointerSize,
    this.maxLines,
    required this.colors,
  });

  const AquaChipLabel.info({
    super.key,
    required this.message,
    this.onLeadingIconTap,
    this.onTrailingIconTap,
    this.isDismissible = false,
    this.margin = const EdgeInsets.all(16),
    this.leadingIcon,
    this.trailingIcon,
    this.variant = AquaChipLabelVariant.normal,
    this.pointerPosition = AquaChipLabelPointerPosition.none,
    this.pointerSize = kDefaultLabelPointerSize,
    this.maxLines,
    required this.colors,
  }) : isInfo = true;

  final String message;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final VoidCallback? onLeadingIconTap;
  final VoidCallback? onTrailingIconTap;
  final EdgeInsets margin;
  final bool isInfo;
  final bool isDismissible;
  final AquaChipLabelVariant variant;
  final AquaChipLabelPointerPosition pointerPosition;
  final double pointerSize;
  final int? maxLines;
  final AquaColors colors;

  Color get _backgroundColor => switch (variant) {
        AquaChipLabelVariant.success => colors.accentSuccessTransparent,
        AquaChipLabelVariant.warning => colors.accentWarningTransparent,
        AquaChipLabelVariant.error => colors.accentDangerTransparent,
        _ => colors.glassInverse.withOpacity(.8),
      };

  EdgeInsets get _contentPadding {
    return EdgeInsets.only(
      left: 16,
      right: 16,
      top: 8 +
          (pointerPosition == AquaChipLabelPointerPosition.top
              ? pointerSize
              : 0),
      bottom: 8 +
          (pointerPosition == AquaChipLabelPointerPosition.bottom
              ? pointerSize
              : 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipPath(
        clipper: _LabelClipper(
          ptrPos: pointerPosition,
          ptrSize: pointerSize,
          borderRadius: kDefaultLabelBorderRadius,
        ),
        child: BackdropFilter(
          filter: variant == AquaChipLabelVariant.normal
              ? ImageFilter.blur(sigmaX: 2, sigmaY: 2)
              : ImageFilter.blur(),
          child: Material(
            elevation: 0,
            color: _backgroundColor,
            child: Container(
              padding: _contentPadding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isInfo) ...[
                    IconButton(
                      icon: leadingIcon ??
                          Icon(
                            Icons.info_outline,
                            color: switch (variant) {
                              AquaChipLabelVariant.success =>
                                colors.accentSuccess,
                              AquaChipLabelVariant.warning =>
                                colors.accentWarning,
                              AquaChipLabelVariant.error => colors.accentDanger,
                              AquaChipLabelVariant.normal => colors.textInverse,
                            },
                          ),
                      onPressed: onLeadingIconTap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      splashRadius: 4,
                      iconSize: 18,
                      color: colors.textInverse,
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: AquaText.body2Medium(
                      text: message,
                      maxLines: maxLines,
                      textAlign: TextAlign.center,
                      color: switch (variant) {
                        AquaChipLabelVariant.success => colors.accentSuccess,
                        AquaChipLabelVariant.warning => colors.accentWarning,
                        AquaChipLabelVariant.error => colors.accentDanger,
                        AquaChipLabelVariant.normal => colors.textInverse,
                      },
                    ),
                  ),
                  if (isDismissible) ...[
                    const SizedBox(width: 16),
                    IconButton(
                      icon: trailingIcon ??
                          Icon(
                            Icons.close,
                            color: switch (variant) {
                              AquaChipLabelVariant.success =>
                                colors.accentSuccess,
                              AquaChipLabelVariant.warning =>
                                colors.accentWarning,
                              AquaChipLabelVariant.error => colors.accentDanger,
                              AquaChipLabelVariant.normal =>
                                colors.textTertiary,
                            },
                          ),
                      onPressed: onTrailingIconTap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      splashRadius: 4,
                      iconSize: 18,
                      color: switch (variant) {
                        AquaChipLabelVariant.success => colors.accentSuccess,
                        AquaChipLabelVariant.warning => colors.accentWarning,
                        AquaChipLabelVariant.error => colors.accentDanger,
                        AquaChipLabelVariant.normal => colors.textTertiary,
                      },
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelClipper extends CustomClipper<Path> {
  const _LabelClipper({
    required this.ptrPos,
    required this.ptrSize,
    required this.borderRadius,
  });

  final AquaChipLabelPointerPosition ptrPos;
  final double ptrSize;
  final double borderRadius;

  @override
  Path getClip(Size size) {
    final path = Path();

    // Calculate base rectangle bounds
    const rectLeft = 0.0;
    final rectTop = ptrPos == AquaChipLabelPointerPosition.top ? ptrSize : 0.0;
    final rectRight = size.width;
    final rectBottom = ptrPos == AquaChipLabelPointerPosition.bottom
        ? size.height - ptrSize
        : size.height;

    // Add the main rounded rectangle
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom),
        Radius.circular(borderRadius),
      ),
    );

    // Add pointer based on position
    if (ptrPos != AquaChipLabelPointerPosition.none) {
      switch (ptrPos) {
        case AquaChipLabelPointerPosition.top:
          path.moveTo(size.width / 2 - ptrSize, ptrSize);
          path.lineTo(size.width / 2, 0);
          path.lineTo(size.width / 2 + ptrSize, ptrSize);
          break;
        case AquaChipLabelPointerPosition.bottom:
          path.moveTo(size.width / 2 - ptrSize, size.height - ptrSize);
          path.lineTo(size.width / 2, size.height);
          path.lineTo(size.width / 2 + ptrSize, size.height - ptrSize);
          break;
        case AquaChipLabelPointerPosition.none:
          break;
      }
    }

    return path;
  }

  @override
  bool shouldReclip(_LabelClipper oldClipper) =>
      ptrPos != oldClipper.ptrPos ||
      ptrSize != oldClipper.ptrSize ||
      borderRadius != oldClipper.borderRadius;
}
