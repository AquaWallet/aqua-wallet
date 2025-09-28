import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

const kDefaultTooltipDuration = Duration(seconds: 4);
const kPermanentTooltipDuration = Duration(days: 1);
const kDefaultPointerSize = 8.0;
const kDefaultBorderRadius = 32.0;

enum AquaTooltipVariant {
  normal,
  success,
  warning,
  error,
}

enum AquaTooltipPointerPosition {
  none,
  top,
  bottom,
}

class AquaTooltip extends StatelessWidget {
  const AquaTooltip({
    super.key,
    required this.message,
    this.onLeadingIconTap,
    this.onTrailingIconTap,
    this.isDismissible = false,
    this.isInfo = false,
    this.leadingIcon,
    this.margin = const EdgeInsets.all(16),
    this.trailingIcon,
    this.variant = AquaTooltipVariant.normal,
    this.pointerPosition = AquaTooltipPointerPosition.none,
    this.pointerSize = kDefaultPointerSize,
    required this.colors,
  });

  const AquaTooltip.info({
    super.key,
    required this.message,
    this.onLeadingIconTap,
    this.onTrailingIconTap,
    this.isDismissible = false,
    this.margin = const EdgeInsets.all(16),
    this.leadingIcon,
    this.trailingIcon,
    this.variant = AquaTooltipVariant.normal,
    this.pointerPosition = AquaTooltipPointerPosition.none,
    this.pointerSize = kDefaultPointerSize,
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
  final AquaTooltipVariant variant;
  final AquaTooltipPointerPosition pointerPosition;
  final double pointerSize;
  final AquaColors colors;

  Color get _backgroundColor => switch (variant) {
        AquaTooltipVariant.success => colors.accentSuccessTransparent,
        AquaTooltipVariant.warning => colors.accentWarningTransparent,
        AquaTooltipVariant.error => colors.accentDangerTransparent,
        _ => colors.glassInverse.withOpacity(.8),
      };

  EdgeInsets get _contentPadding {
    return EdgeInsets.only(
      left: 16,
      right: 16,
      top: 8 +
          (pointerPosition == AquaTooltipPointerPosition.top ? pointerSize : 0),
      bottom: 8 +
          (pointerPosition == AquaTooltipPointerPosition.bottom
              ? pointerSize
              : 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipPath(
        clipper: _TooltipClipper(
          ptrPos: pointerPosition,
          ptrSize: pointerSize,
          borderRadius: kDefaultBorderRadius,
        ),
        child: BackdropFilter(
          filter: variant == AquaTooltipVariant.normal
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
                              AquaTooltipVariant.success =>
                                colors.accentSuccess,
                              AquaTooltipVariant.warning =>
                                colors.accentWarning,
                              AquaTooltipVariant.error => colors.accentDanger,
                              AquaTooltipVariant.normal => colors.textInverse,
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
                      color: switch (variant) {
                        AquaTooltipVariant.success => colors.accentSuccess,
                        AquaTooltipVariant.warning => colors.accentWarning,
                        AquaTooltipVariant.error => colors.accentDanger,
                        AquaTooltipVariant.normal => colors.textInverse,
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
                              AquaTooltipVariant.success =>
                                colors.accentSuccess,
                              AquaTooltipVariant.warning =>
                                colors.accentWarning,
                              AquaTooltipVariant.error => colors.accentDanger,
                              AquaTooltipVariant.normal => colors.textTertiary,
                            },
                          ),
                      onPressed: onTrailingIconTap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      splashRadius: 4,
                      iconSize: 18,
                      color: switch (variant) {
                        AquaTooltipVariant.success => colors.accentSuccess,
                        AquaTooltipVariant.warning => colors.accentWarning,
                        AquaTooltipVariant.error => colors.accentDanger,
                        AquaTooltipVariant.normal => colors.textTertiary,
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

  static void show(
    BuildContext context, {
    Key? key,
    required String message,
    Widget? leadingIcon,
    Widget? trailingIcon,
    VoidCallback? onLeadingIconTap,
    VoidCallback? onTrailingIconTap,
    bool isDismissible = false,
    bool isInfo = false,
    Duration? duration,
    bool useRootNavigator = false,
    AquaTooltipVariant variant = AquaTooltipVariant.normal,
    AquaTooltipPointerPosition pointerPosition =
        AquaTooltipPointerPosition.none,
    double pointerSize = kDefaultPointerSize,
    required AquaColors colors,
  }) {
    // Use Overlay instead of SnackBar to ensure the tooltip appears above everything
    final overlayState = Overlay.of(context, rootOverlay: true);

    final tooltipDuration = duration ??
        (isDismissible ? kPermanentTooltipDuration : kDefaultTooltipDuration);

    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !isDismissible,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: IntrinsicWidth(
                  child: AquaTooltip(
                    key: key,
                    message: message,
                    leadingIcon: leadingIcon,
                    trailingIcon: trailingIcon,
                    onLeadingIconTap: onLeadingIconTap,
                    onTrailingIconTap: () {
                      overlayEntry.remove();
                      onTrailingIconTap?.call();
                    },
                    isDismissible: isDismissible,
                    isInfo: isInfo,
                    margin: EdgeInsets.zero,
                    variant: variant,
                    pointerPosition: pointerPosition,
                    pointerSize: pointerSize,
                    colors: colors,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Insert the overlay entry
    overlayState.insert(overlayEntry);

    // Remove the overlay entry after the specified duration if not dismissible
    if (!isDismissible) {
      Future.delayed(tooltipDuration, () {
        overlayEntry.remove();
      });
    }
  }
}

class _TooltipClipper extends CustomClipper<Path> {
  const _TooltipClipper({
    required this.ptrPos,
    required this.ptrSize,
    required this.borderRadius,
  });

  final AquaTooltipPointerPosition ptrPos;
  final double ptrSize;
  final double borderRadius;

  @override
  Path getClip(Size size) {
    final path = Path();

    // Calculate base rectangle bounds
    const rectLeft = 0.0;
    final rectTop = ptrPos == AquaTooltipPointerPosition.top ? ptrSize : 0.0;
    final rectRight = size.width;
    final rectBottom = ptrPos == AquaTooltipPointerPosition.bottom
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
    if (ptrPos != AquaTooltipPointerPosition.none) {
      switch (ptrPos) {
        case AquaTooltipPointerPosition.top:
          path.moveTo(size.width / 2 - ptrSize, ptrSize);
          path.lineTo(size.width / 2, 0);
          path.lineTo(size.width / 2 + ptrSize, ptrSize);
          break;
        case AquaTooltipPointerPosition.bottom:
          path.moveTo(size.width / 2 - ptrSize, size.height - ptrSize);
          path.lineTo(size.width / 2, size.height);
          path.lineTo(size.width / 2 + ptrSize, size.height - ptrSize);
          break;
        case AquaTooltipPointerPosition.none:
          break;
      }
    }

    return path;
  }

  @override
  bool shouldReclip(_TooltipClipper oldClipper) =>
      ptrPos != oldClipper.ptrPos ||
      ptrSize != oldClipper.ptrSize ||
      borderRadius != oldClipper.borderRadius;
}
