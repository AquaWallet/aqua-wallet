import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

const kDefaultTooltipDuration = Duration(seconds: 4);
const kPermanentTooltipDuration = Duration(days: 1);
const kDefaultPointerSize = 8.0;
const kDefaultBorderRadius = 32.0;
const kTooltipScreenPadding = 16.0;
const kTooltipAnchorGap = 8.0;

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
    this.pointerSize = kDefaultLabelPointerSize,
    this.maxLines,
    required this.colors,
  });

  // Static callback to dismiss the currently active tooltip
  static VoidCallback? _dismissCurrentTooltip;

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
  final AquaTooltipVariant variant;
  final AquaTooltipPointerPosition pointerPosition;
  final double pointerSize;
  final int? maxLines;
  final AquaColors colors;

  @override
  Widget build(BuildContext context) {
    final chipLabelVariant = switch (variant) {
      AquaTooltipVariant.normal => AquaChipLabelVariant.normal,
      AquaTooltipVariant.success => AquaChipLabelVariant.success,
      AquaTooltipVariant.warning => AquaChipLabelVariant.warning,
      AquaTooltipVariant.error => AquaChipLabelVariant.error,
    };

    final chipLabelPointerPosition = switch (pointerPosition) {
      AquaTooltipPointerPosition.none => AquaChipLabelPointerPosition.none,
      AquaTooltipPointerPosition.top => AquaChipLabelPointerPosition.top,
      AquaTooltipPointerPosition.bottom => AquaChipLabelPointerPosition.bottom,
    };

    return AquaChipLabel(
      message: message,
      onLeadingIconTap: onLeadingIconTap,
      onTrailingIconTap: onTrailingIconTap,
      isDismissible: isDismissible,
      isInfo: isInfo,
      leadingIcon: leadingIcon,
      margin: margin,
      trailingIcon: trailingIcon,
      variant: chipLabelVariant,
      pointerPosition: chipLabelPointerPosition,
      pointerSize: pointerSize,
      maxLines: maxLines,
      colors: colors,
    );
  }

  static void show(
    BuildContext context, {
    Key? key,
    GlobalKey? anchorKey,
    required String message,
    Widget? leadingIcon,
    Widget? trailingIcon,
    VoidCallback? onLeadingIconTap,
    VoidCallback? onTrailingIconTap,
    VoidCallback? onToolTipTap,
    bool isDismissible = false,
    bool isInfo = false,
    Duration? duration,
    bool useRootNavigator = false,
    AquaTooltipVariant variant = AquaTooltipVariant.normal,
    AquaTooltipPointerPosition pointerPosition =
        AquaTooltipPointerPosition.none,
    double pointerSize = kDefaultLabelPointerSize,
    int? maxLines,
    required AquaColors colors,
  }) {
    // Dismiss any existing tooltip before showing a new one
    _dismissCurrentTooltip?.call();

    // Use Overlay instead of SnackBar to ensure the tooltip appears above everything
    final overlayState = Overlay.of(context, rootOverlay: true);

    final tooltipDuration = duration ??
        (isDismissible ? kPermanentTooltipDuration : kDefaultTooltipDuration);

    final tooltipGlobalKey =
        key is GlobalKey ? key : GlobalKey(debugLabel: 'AquaTooltipOverlayKey');

    final positionNotifier = ValueNotifier<_TooltipPosition?>(null);
    var isRemoved = false;

    late final OverlayEntry overlayEntry;

    void removeTooltip() {
      if (isRemoved) {
        return;
      }
      isRemoved = true;
      overlayEntry.remove();
      positionNotifier.dispose();
      // Clear the dismiss callback if this is the current tooltip
      if (_dismissCurrentTooltip == removeTooltip) {
        _dismissCurrentTooltip = null;
      }
    }

    // Store the dismiss callback for this tooltip
    _dismissCurrentTooltip = removeTooltip;

    bool updatePosition() {
      if (anchorKey == null) {
        return false;
      }

      final anchorContext = anchorKey.currentContext;
      final tooltipContext = tooltipGlobalKey.currentContext;
      final overlayRenderObject =
          overlayState.context.findRenderObject() as RenderBox?;

      if (anchorContext == null ||
          tooltipContext == null ||
          overlayRenderObject == null) {
        return false;
      }

      final anchorRenderObject = anchorContext.findRenderObject() as RenderBox?;
      final tooltipRenderObject =
          tooltipContext.findRenderObject() as RenderBox?;

      if (anchorRenderObject == null || tooltipRenderObject == null) {
        return false;
      }

      final anchorOffset = anchorRenderObject.localToGlobal(Offset.zero,
          ancestor: overlayRenderObject);
      final anchorSize = anchorRenderObject.size;
      final tooltipSize = tooltipRenderObject.size;
      final overlaySize = overlayRenderObject.size;

      var left =
          anchorOffset.dx + (anchorSize.width / 2) - (tooltipSize.width / 2);

      left = math.max(
        kTooltipScreenPadding,
        math.min(
          left,
          overlaySize.width - tooltipSize.width - kTooltipScreenPadding,
        ),
      );

      double top;
      switch (pointerPosition) {
        case AquaTooltipPointerPosition.top:
          top = anchorOffset.dy + anchorSize.height + kTooltipAnchorGap;
          break;
        case AquaTooltipPointerPosition.bottom:
          top = anchorOffset.dy - tooltipSize.height - kTooltipAnchorGap;
          break;
        case AquaTooltipPointerPosition.none:
          top = anchorOffset.dy - tooltipSize.height - kTooltipAnchorGap;
          break;
      }

      top = math.max(
        kTooltipScreenPadding,
        math.min(
          top,
          overlaySize.height - tooltipSize.height - kTooltipScreenPadding,
        ),
      );

      positionNotifier.value = _TooltipPosition(left: left, top: top);
      return true;
    }

    void schedulePositionUpdate() {
      if (anchorKey == null) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isRemoved || !overlayEntry.mounted) {
          return;
        }
        final success = updatePosition();
        if (!success) {
          schedulePositionUpdate();
        }
      });
    }

    overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return ValueListenableBuilder<_TooltipPosition?>(
          valueListenable: positionNotifier,
          builder: (context, position, _) {
            Widget tooltipContent = GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onToolTipTap,
              child: AquaTooltip(
                key: tooltipGlobalKey,
                message: message,
                leadingIcon: leadingIcon,
                trailingIcon: trailingIcon,
                onLeadingIconTap: onLeadingIconTap,
                onTrailingIconTap: () {
                  removeTooltip();
                  onTrailingIconTap?.call();
                },
                isDismissible: isDismissible,
                isInfo: isInfo,
                margin: EdgeInsets.zero,
                variant: variant,
                pointerPosition: pointerPosition,
                pointerSize: pointerSize,
                maxLines: maxLines,
                colors: colors,
              ),
            );

            if (key != null && !identical(key, tooltipGlobalKey)) {
              tooltipContent = KeyedSubtree(
                key: key,
                child: tooltipContent,
              );
            }

            Widget buildSurface({required bool centered}) {
              final screenWidth = MediaQuery.of(context).size.width;
              final maxTooltipWidth = screenWidth - kTooltipScreenPadding * 2;
              Widget surface = ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxTooltipWidth),
                  child: tooltipContent);
              if (centered) {
                surface = Center(child: surface);
              }
              return IgnorePointer(
                ignoring: !isDismissible,
                child: Material(
                  color: Colors.transparent,
                  child: surface,
                ),
              );
            }

            if (anchorKey != null && position != null) {
              return Positioned(
                left: position.left,
                top: position.top,
                child: buildSurface(centered: false),
              );
            }

            return Positioned(
              bottom: kTooltipScreenPadding,
              left: 0,
              right: 0,
              child: buildSurface(centered: true),
            );
          },
        );
      },
    );

    // Insert the overlay entry
    overlayState.insert(overlayEntry);

    if (anchorKey != null) {
      schedulePositionUpdate();
    }

    // Remove the overlay entry after the specified duration if not dismissible
    if (!isDismissible) {
      Future.delayed(tooltipDuration, () {
        removeTooltip();
      });
    }
  }
}

class _TooltipPosition {
  const _TooltipPosition({required this.left, required this.top});

  final double left;
  final double top;
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
