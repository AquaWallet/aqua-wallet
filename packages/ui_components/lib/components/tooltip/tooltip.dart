import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ui_components/components/components.dart';

const kDefaultTooltipDuration = Duration(seconds: 4);
const kPermanentTooltipDuration = Duration(days: 1);

class AquaTooltip extends StatelessWidget {
  const AquaTooltip({
    super.key,
    required this.message,
    this.onLeadingIconTap,
    this.onTrailingIconTap,
    this.backgroundColor,
    this.foregroundColor,
    this.trailingIconColor,
    this.isDismissible = false,
    this.isInfo = false,
    this.leadingIcon,
    this.margin = const EdgeInsets.all(16),
    this.trailingIcon,
  });

  const AquaTooltip.info({
    super.key,
    required this.message,
    this.onLeadingIconTap,
    this.onTrailingIconTap,
    this.backgroundColor,
    this.foregroundColor,
    this.trailingIconColor,
    this.isDismissible = false,
    this.margin = const EdgeInsets.all(16),
    this.leadingIcon,
    this.trailingIcon,
  }) : isInfo = true;

  final String message;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final VoidCallback? onLeadingIconTap;
  final VoidCallback? onTrailingIconTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? trailingIconColor;
  final EdgeInsets margin;
  final bool isInfo;
  final bool isDismissible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(32),
            color:
                (backgroundColor ?? theme.colorScheme.surface).withOpacity(.8),
            child: Container(
              padding: isDismissible
                  ? EdgeInsetsDirectional.only(
                      start: leadingIcon != null ? 8 : 16,
                      end: 8,
                      top: 8,
                      bottom: 8,
                    )
                  : const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isInfo) ...[
                    IconButton(
                      icon: leadingIcon ??
                          Icon(
                            Icons.info_outline,
                            color: foregroundColor,
                          ),
                      onPressed: onLeadingIconTap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      splashRadius: 4,
                      iconSize: 18,
                      color: foregroundColor,
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
                      color: foregroundColor,
                    ),
                  ),
                  if (isDismissible) ...[
                    const SizedBox(width: 16),
                    IconButton(
                      icon: trailingIcon ??
                          Icon(
                            Icons.close,
                            color: trailingIconColor ?? foregroundColor,
                          ),
                      onPressed: onTrailingIconTap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      splashRadius: 4,
                      iconSize: 18,
                      color: trailingIconColor ?? foregroundColor,
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
    required String message,
    Widget? leadingIcon,
    Widget? trailingIcon,
    VoidCallback? onLeadingIconTap,
    VoidCallback? onTrailingIconTap,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? trailingIconColor,
    bool isDismissible = false,
    bool isInfo = false,
    Duration? duration,
    bool useRootNavigator = false,
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
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                    trailingIconColor: trailingIconColor,
                    margin: EdgeInsets.zero,
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
